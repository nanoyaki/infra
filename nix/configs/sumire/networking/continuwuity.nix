{
  flake.nixosModules.sumire-continuwuity =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      inherit (config) sec tpl plh;

      cfg = config.services.matrix-continuwuity;
    in

    {
      sec = {
        "continuwuity/registration" = {
          inherit (cfg) group;
          owner = cfg.user;
          mode = "400";
        };

        "continuwuity/oidc-secret".owner = cfg.user;
        "mail/no-reply@serdexmethylpheni.date" = { };
      };

      tpl."continuwuity.env".file = pkgs.writeEnv "continuwuity.env.template" {
        CONTINUWUITY_SMTP__CONNECTION_URI = "smtps://no-reply%40serdexmethylpheni.date:${
          plh."mail/no-reply@serdexmethylpheni.date"
        }@mail.nanoyaki.space:465";
      };

      # Matrix port
      networking.firewall.allowedTCPPorts = [ 8448 ];

      security.acme.certs."serdexmethylpheni.date".environmentFile = tpl."porkbun.env".path;
      services.caddy.virtualHosts."serdexmethylpheni.date" = {
        useACMEHost = "serdexmethylpheni.date";
        extraConfig = ''
          import continuwuity_https
        '';
      };

      services.caddy.virtualHosts."serdexmethylpheni.date:8448" = {
        useACMEHost = "serdexmethylpheni.date";
        extraConfig = ''
          import continuwuity_federation
        '';
      };

      services.caddy.extraConfig = ''
        (continuwuity_https) {
          @https {
            path /_matrix* /_continuwuity* /.well-known/matrix*
            # Do not explicitly block federation on this port?
            # not path /_matrix/federation* /_matrix/key*
          }
          
          @frontend path /home
          handle @frontend {
            rewrite /
            reverse_proxy unix/@continuwuity
          }
          
          handle @https {
            reverse_proxy unix/@continuwuity   
          }
        }

        (continuwuity_federation) {
          @federation path /_matrix/federation* /_matrix/key*

          handle @federation {
            reverse_proxy unix/@continuwuity
          }
        }
      '';

      # Based on sodiboo's proprietary code of
      # which i stole a bunch https://github.com/sodiboo/system
      systemd.sockets.continuwuity-proxy = {
        wantedBy = [ "sockets.target" ];

        listenStreams = [ "@continuwuity" ];
        socketConfig = {
          SocketUser = "caddy";
          SocketGroup = "caddy";
          SocketMode = "0640";

          # if the upstream service is ready too early, its socket may not exist yet
          # and therefore the socket proxy startup is skipped.
          # but, that's a "cheap" fail; it shouldn't prevent triggering the socket proxy ever again.
          TriggerLimitBurst = 0;

          # additionally, let's not spam the logs: when inactive, poll once every 3 seconds.
          PollLimitBurst = 1;
          PollLimitIntervalSec = 3;
          # and after one is skipped, flush the rest.
          FlushPending = true;
        };
      };

      systemd.services.continuwuity-proxy = {
        requires = [
          "continuwuity.service"
          "continuwuity-proxy.socket"
        ];
        after = [
          "continuwuity.service"
          "continuwuity-proxy.socket"
        ];

        unitConfig = {
          ConditionPathExists = [ cfg.settings.global.unix_socket_path ];
          AssertPathIsDirectory = [ "!${cfg.settings.global.unix_socket_path}" ];
        };

        confinement = {
          enable = true;
          mode = "chroot-only";
        };

        serviceConfig = {
          # systemd-socket-proxyd is prone to exceeding the nofile soft limit.
          # increase it to the default hard limit.
          LimitNOFILE = 524288;

          Type = "notify";
          ExecStart = lib.concatStringsSep " " [
            "${config.systemd.package}/lib/systemd/systemd-socket-proxyd"
            "--connections-max"
            (toString 256)
            "--exit-idle-time"
            "infinity"
            "/upstream"
          ];

          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          PrivateTmp = true;
          PrivateMounts = true;
          PrivateDevices = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;

          ProcSubset = "pid";
          ProtectProc = "invisible";

          NoNewPrivileges = true;

          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged @resources"
            "~@chown @setuid @keyring"
            "~select pselect6 pselect6_time64 _newselect"
          ];

          UMask = "0777";
          DynamicUser = true;

          RestrictAddressFamilies = "AF_UNIX";

          # systemd recommends *not* using `BindPaths` in a `DynamicUser`.
          # in particular, you can potentially leak the dynamic uid through this.
          # however, systemd-socket-proxyd never creates or chmods anything, so it's a non-issue.
          # and, it also doesn't proxy ancillary data (fds), so nothing can leak through that either.
          BindPaths = [ "${cfg.settings.global.unix_socket_path}:/upstream" ];

          # in an fs socket (but not an abstract socket),
          # we can always isolate the networking namespace
          PrivateNetwork = true;

          # Bypass file perms
          AmbientCapabilities = [ "CAP_DAC_OVERRIDE" ];
          CapabilityBoundingSet = [ "CAP_DAC_OVERRIDE" ];
        };
      };

      users.users.${cfg.user}.extraGroups = [ "turn-secret" ];

      systemd.services.continuwuity.serviceConfig.EnvironmentFile = tpl."continuwuity.env".path;

      services.matrix-continuwuity.enable = true;
      services.matrix-continuwuity.settings.global = {
        server_name = "serdexmethylpheni.date";
        max_request_size = 1024 * 1024 * 1024;
        unix_socket_path = "/run/continuwuity/socket";
        unix_socket_perms = 660;

        database_backups_to_keep = 3;
        # 4 - IPv6 then IPv4
        ip_lookup_strategy = 4;
        # Caddy's default "real ip" header
        request_ip_source = "x_forwarded_for";

        registration_token_file = sec."continuwuity/registration".path;
        allow_registration = true;
        suspend_on_register = true;

        oauth.compatibility_mode = "hybrid";
        oauth.oidc = {
          discovery_url = "https://id.serdexmethylpheni.date";
          client_id = "9a4974c7-dce6-498e-aca3-59ee7535d24f";
          client_secret_file = sec."continuwuity/oidc-secret".path;

          # Claims
          additional_scopes = [
            "openid"
            "profile"
            "email"
          ];
          email_claim = "email";
          profile_key_map = {
            avatar_url = "picture";
            display_name = "preferred_username";
          };
          profile_key_import_mode = "on_registration";
        };

        smtp.sender = "Matrix <no-reply@serdexmethylpheni.date>";

        url_preview_check_root_domain = true;
        url_preview_domain_explicit_allowlist = [
          "duckduckgo.com"

          # Own domains
          "nanoyaki.space"
          "theless.one"
          "hanakretzer.de"
          "aslija.com"
        ];

        url_preview_max_spider_size = 1024 * 1024 * 10;
        url_preview_allow_audio_video = true;

        trusted_servers = [
          "matrix.org"
          "federation.nexus"
        ];
        well_known = {
          client = "https://serdexmethylpheni.date";
          server = "serdexmethylpheni.date:443";
        };

        matrix_rtc.foci = [
          {
            type = "livekit";
            livekit_service_url = "https://rtc.serdexmethylpheni.date";
          }
        ];

        turn_ttl = 86400;
        turn_secret_file = sec."coturn/auth-secret".path;
        turn_uris = [
          "turns:turn.serdexmethylpheni.date?transport=udp"
          "turns:turn.serdexmethylpheni.date?transport=tcp"
        ];
      };
    };
}
