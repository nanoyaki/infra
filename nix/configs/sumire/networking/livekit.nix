{
  flake.nixosModules.sumire-livekit =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib) mkForce mkIf;
      inherit (config) plh tpl sec;

      cfg = config.services.livekit;
    in

    {
      sec."livekit/matrix-rtc-key" = { };
      sec."livekit/matrix-rtc-secret" = { };

      tpl."livekit.keys".file = pkgs.writeYaml "livekit.keys.template" {
        ${plh."livekit/matrix-rtc-key"} = plh."livekit/matrix-rtc-secret";
      };

      networking.firewall.allowedTCPPorts = [ cfg.settings.rtc.tcp_port ];
      networking.firewall.allowedUDPPortRanges = [
        {
          from = cfg.settings.rtc.port_range_start;
          to = cfg.settings.rtc.port_range_end;
        }
      ];

      security.acme.certs."rtc.serdexmethylpheni.date" = {
        environmentFile = tpl."porkbun.env".path;
        reloadServices = [ "caddy.service" ];
      };

      services.caddy.virtualHosts."rtc.serdexmethylpheni.date" = {
        useACMEHost = "rtc.serdexmethylpheni.date";
        extraConfig = ''
          @jwt path /sfu/get* /healthz* /get_token*
          route @jwt {
            reverse_proxy [::1]:${toString config.services.lk-jwt-service.port}
          }

          reverse_proxy [::1]:${toString config.services.livekit.settings.port}
        '';
      };

      users.groups.livekit = { };
      users.users.livekit = {
        description = "Livekit SFU Service User";
        group = "livekit";
        isSystemUser = true;
        extraGroups = [ "turn-secret" ];
      };

      systemd.services.livekit.serviceConfig = {
        DynamicUser = mkForce false;
        User = "livekit";
        Group = "livekit";
        ReadOnlyPaths = [ sec."coturn/auth-secret".path ];
      };

      services.livekit = {
        enable = true;
        keyFile = tpl."livekit.keys".path;

        settings = {
          port = 7880;
          room.auto_create = false;

          rtc = {
            tcp_port = 7881;
            use_external_ip = true;
            port_range_start = 50100;
            port_range_end = 50200;

            turn_servers = [
              {
                host = "turn.serdexmethylpheni.date";
                port = 3478;
                protocol = "udp";
                secret_file = sec."coturn/auth-secret".path;
              }
              {
                host = "turn.serdexmethylpheni.date";
                port = 3478;
                protocol = "tcp";
                secret_file = sec."coturn/auth-secret".path;
              }
              {
                host = "turn.serdexmethylpheni.date";
                port = 5349;
                protocol = "tls";
                secret_file = sec."coturn/auth-secret".path;
              }
            ];
          };
        };
      };

      systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS =
        "serdexmethylpheni.date";
      services.lk-jwt-service = {
        enable = true;
        port = 8080;
        livekitUrl = "wss://rtc.serdexmethylpheni.date";
        keyFile = tpl."livekit.keys".path;
      };

      services.matrix-continuwuity =
        mkIf (config.services.lk-jwt-service.enable && config.services.livekit.enable)
          {
            settings.global.matrix_rtc.foci = [
              {
                type = "livekit";
                livekit_service_url = "https://rtc.serdexmethylpheni.date";
              }
            ];
          };

      programs.dnscontrol.domains."serdexmethylpheni.date".cname.rtc.value = "@";
    };
}
