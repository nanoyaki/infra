{
  flake.nixosModules.thelessone-forgejo =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config)
        dmn
        prt
        sec
        plh
        tpl
        ;

      cfg = config.services.forgejo;

      user = "git";
      group = "git";
    in

    {
      users.groups.${group} = { };

      users.users.${user} = {
        inherit group;

        home = cfg.stateDir;
        useDefaultShell = true;
        isSystemUser = true;

        extraGroups = [ "podman" ];
      };

      sec = {
        "forgejo/kikyo" = { };
        "forgejo/syakuyaku" = { };
        "forgejo/botan" = { };
        "forgejo/kigiku" = { };
        "mailserver/git" = { };

        "forgejo/users/nanoyaki".owner = cfg.user;
        "forgejo/oidc/id".owner = cfg.user;
        "forgejo/oidc/secret".owner = cfg.user;
      };

      tpl = {
        "kikyo.env".file = pkgs.writeEnv "kikyo.env.template" {
          TOKEN = plh."forgejo/kikyo";
        };

        "syakuyaku.env".file = pkgs.writeEnv "syakuyaku.env.template" {
          TOKEN = plh."forgejo/syakuyaku";
        };

        "botan.env".file = pkgs.writeEnv "botan.env.template" {
          TOKEN = plh."forgejo/botan";
          REGISTRY_AUTH_FILE = tpl."auth.json".path;
        };

        "kigiku.env".file = pkgs.writeEnv "kigiku.env.template" {
          TOKEN = plh."forgejo/kigiku";
        };
      };

      systemd.services.gitea-runner-kikyo.environment = {
        inherit (config.environment.sessionVariables) NIX_PATH;
      };

      systemd.services.gitea-runner-syakuyaku.environment = {
        inherit (config.environment.sessionVariables) NIX_PATH;
      };

      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;

        instances = rec {
          kikyo = {
            enable = true;
            name = "kikyo";
            url = "https://${dmn.git}";
            tokenFile = tpl."kikyo.env".path;

            settings.runner.capacity = 8;

            labels = [ "native:host" ];
            hostPackages = with pkgs; [
              # essentials
              bash
              coreutils
              curl
              gawk
              git
              git-lfs
              gnused
              nodejs
              wget
              which
              iputils
              tea
              jq

              nix
              nixos-rebuild
              nix-eval-jobs
              openssh
              statix
              dix
              inotify-tools
              nh
              attic-client
            ];
          };

          syakuyaku = kikyo // {
            name = "syakuyaku";
            tokenFile = tpl."syakuyaku.env".path;
          };

          kigiku = kikyo // {
            name = "kigiku";
            tokenFile = tpl."kigiku.env".path;
          };

          botan = {
            enable = true;
            name = "botan";
            url = "https://${dmn.git}";
            tokenFile = tpl."botan.env".path;

            settings.runner.capacity = 8;

            labels = [
              "debian-latest:docker://debian:latest"
              "debian-stable:docker://debian:stable"

              "ubuntu-latest:docker://ubuntu:latest"
              "ubuntu-22.04:docker://ubuntu:jammy"

              "nix:docker://ghcr.io/nixos/nix:latest"
              "rust:docker://rust:latest"
            ];
          };
        };
      };

      sec."containers/docker" = { };
      tpl."auth.json" = {
        content = builtins.toJSON {
          auths."docker.io".auth = plh."containers/docker";
        };

        path = "/etc/containers/auth.json";
        mode = "440";
        group = "podman";
      };

      systemd.tmpfiles.settings.podman."/root/.config/containers/auth.json"."L+".argument =
        tpl."auth.json".path;

      # Use podman instead since rootless docker
      # isn't supported by the forgejo nixos module
      virtualisation.containers = {
        enable = true;
        registries.search = [
          "quay.io"
          "ghcr.io"
          "docker.io"
        ];
      };

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings = {
          dns_enabled = true;
          ipv6_enabled = true;
        };
      };

      networking.firewall.interfaces."\"podman*\"".allowedUDPPorts = [ 53 ];

      sec = {
        "forgejo/signing".owner = cfg.user;
        "forgejo/signing.pub".owner = cfg.user;
        "forgejo/mailer-password".owner = cfg.user;
      };

      prt.forgejo = 8004;
      dmn.git = "git.theless.one";

      systemd.services.forgejo.wantedBy = lib.mkForce [ "server-services.target" ];
      services.forgejo = {
        enable = true;
        lfs.enable = true;
        package = pkgs.forgejo;

        inherit user group;
        stateDir = "/var/lib/${user}";

        database = {
          inherit user;

          name = user;
          type = "postgres";
        };

        dump = {
          enable = true;
          interval = "hourly";
          file = "forgejo-backup-dump";
          type = "tar";
        };

        settings = {
          server = {
            DOMAIN = dmn.git;
            ROOT_URL = "https://${dmn.git}/";
            HTTP_PORT = prt.forgejo;

            DISABLE_SSH = false;
          };

          service = {
            ENABLE_NOTIFY_MAIL = true;

            # OIDC
            DISABLE_REGISTRATION = false;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
            ENABLE_INTERNAL_SIGNIN = false;
            # Disable API non-OIDC auth
            ENABLE_BASIC_AUTHENTICATION = false;
          };

          openid.ENABLE_OPENID_SIGNUP = true;

          actions = {
            ENABLED = true;
            DEFAULT_ACTIONS_URL = "github";
          };

          webhook.ALLOWED_HOST_LIST = "external,loopback";

          mailer = {
            ENABLED = true;
            FROM = "git@${dmn.self}";
            PROTOCOL = "smtps";
            SMTP_ADDR = dmn.mail;
            SMTP_PORT = prt.smtp-tls;
            USER = "git@${dmn.self}";
          };

          "repository.signing" = {
            FORMAT = "ssh";
            SIGNING_KEY = sec."forgejo/signing.pub".path;
            SIGNING_NAME = "forgejo ${dmn.git}";
            SIGNING_EMAIL = "git@${dmn.self}";
          };
        };

        secrets.mailer.PASSWD = sec."forgejo/mailer-password".path;
      };

      thelessone.caddy.vHost.${dmn.git}.extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString prt.forgejo-anubis} {
          header_up X-Real-Ip {remote_host}
          header_up X-Http-Version {http.request.proto}
        }
      '';

      mailserver.accounts."git@${dmn.self}" = {
        sendOnly = true;
        hashedPasswordFile = sec."mailserver/git".path;
      };

      thelessone.backups.forgejo.paths = [ cfg.stateDir ];

      prt.forgejo-anubis = 8005;

      services.anubis.instances.forgejo.settings = {
        TARGET = "http://127.0.0.1:${toString prt.forgejo}";
        BIND = ":${toString prt.forgejo-anubis}";
        BIND_NETWORK = "tcp";
        SERVE_ROBOTS_TXT = true;
        WEBMASTER_EMAIL = "contact@nanoyaki.space";
        DIFFICULTY = 5;
      };

      systemd.services.forgejo.path = [ cfg.package ];
      systemd.services.forgejo.preStart = ''
        if ! forgejo admin auth list | grep -q PocketID; then
          forgejo admin auth add-oauth \
            --name "PocketID" \
            --provider "openidConnect" \
            --key "$(cat ${sec."forgejo/oidc/id".path})" \
            --secret "$(cat ${sec."forgejo/oidc/secret".path})" \
            --auto-discover-url "https://${dmn.pocket-id}/.well-known/openid-configuration" \
            --scopes "openid email profile" \
            --icon-url "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pocket-id.svg" \
            --skip-local-2fa \
            --attribute-ssh-public-key "sshpubkey" \
            --admin-group "forgejo_admin" \
            --restricted-group "forgejo_restricted" \
            --group-claim-name "groups"
        fi
      '';
    };
}
