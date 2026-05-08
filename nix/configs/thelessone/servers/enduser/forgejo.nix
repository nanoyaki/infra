{
  flake.nixosModules.thelessone-forgejo =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
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

      sops.secrets = {
        "forgejo/kikyo" = { };
        "forgejo/syakuyaku" = { };
        "forgejo/botan" = { };
        "forgejo/kigiku" = { };
        "mailserver/git" = { };

        "forgejo/users/nanoyaki".owner = cfg.user;
        "forgejo/oidc/id".owner = cfg.user;
        "forgejo/oidc/secret".owner = cfg.user;
      };

      sops.templates = {
        "kikyo.env".file = pkgs.writeEnv "kikyo.env.template" {
          TOKEN = config.sops.placeholder."forgejo/kikyo";
        };

        "syakuyaku.env".file = pkgs.writeEnv "syakuyaku.env.template" {
          TOKEN = config.sops.placeholder."forgejo/syakuyaku";
        };

        "botan.env".file = pkgs.writeEnv "botan.env.template" {
          TOKEN = config.sops.placeholder."forgejo/botan";
          REGISTRY_AUTH_FILE = config.sops.templates."auth.json".path;
        };

        "kigiku.env".file = pkgs.writeEnv "kigiku.env.template" {
          TOKEN = config.sops.placeholder."forgejo/kigiku";
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
            url = "https://git.theless.one";
            tokenFile = config.sops.templates."kikyo.env".path;

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
            tokenFile = config.sops.templates."syakuyaku.env".path;
          };

          kigiku = kikyo // {
            name = "kigiku";
            tokenFile = config.sops.templates."kigiku.env".path;
          };

          botan = {
            enable = true;
            name = "botan";
            url = "https://git.theless.one";
            tokenFile = config.sops.templates."botan.env".path;

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

      sops.secrets."containers/docker" = { };
      sops.templates."auth.json" = {
        content = builtins.toJSON {
          auths."docker.io".auth = config.sops.placeholder."containers/docker";
        };

        path = "/etc/containers/auth.json";
        mode = "440";
        group = "podman";
      };

      systemd.tmpfiles.settings.podman."/root/.config/containers/auth.json"."L+".argument =
        config.sops.templates."auth.json".path;

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

      sops.secrets = {
        "forgejo/signing".owner = cfg.user;
        "forgejo/signing.pub".owner = cfg.user;
        "forgejo/mailer-password".owner = cfg.user;
      };

      systemd.services.forgejo.wantedBy = lib.mkForce [ "server-services.nix" ];
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
            DOMAIN = "git.theless.one";
            ROOT_URL = "https://${cfg.settings.server.DOMAIN}/";
            HTTP_PORT = 12500;

            DISABLE_SSH = false;
          };

          service = {
            ENABLE_NOTIFY_MAIL = true;

            # OIDC
            DISABLE_REGISTRATION = false;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
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
            FROM = "git@theless.one";
            PROTOCOL = "smtps";
            SMTP_ADDR = "mail.theless.one";
            SMTP_PORT = 465;
            USER = "git@theless.one";
          };

          "repository.signing" = {
            FORMAT = "ssh";
            SIGNING_KEY = config.sops.secrets."forgejo/signing.pub".path;
            SIGNING_NAME = "forgejo git.theless.one";
            SIGNING_EMAIL = "git@theless.one";
          };
        };

        secrets.mailer.PASSWD = config.sops.secrets."forgejo/mailer-password".path;
      };

      mailserver.accounts."git@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/git".path;
      };

      systemd.services.borgbackup-job-forgejo.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.forgejo = {
        repo = "/mnt/raid/borgbackup/forgejo";
        doInit = true;

        paths = cfg.stateDir;

        encryption.mode = "none";
        compression = "zstd";

        startAt = "daily";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 14;
          weekly = 12;
          monthly = -1;
        };
      };

      services.anubis.instances.forgejo.settings = {
        TARGET = "http://127.0.0.1:12500";
        BIND = ":12501";
        BIND_NETWORK = "tcp";
      };

      services.newt.blueprint.public-resources.forgejo = {
        name = "Forgejo";
        protocol = "http";
        full-domain = "git.theless.one";
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            port = 12501;
            method = "http";
          }
        ];
      };

      services.newt.blueprint.public-resources.forgejo-ssh = {
        name = "Forgejo SSH";
        protocol = "tcp";
        proxy-port = 22;
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            port = 22;
          }
        ];
      };

      systemd.services.forgejo.path = [ cfg.package ];
      systemd.services.forgejo.preStart = ''
        forgejo admin user create \
          --admin \
          --email "hanakretzer@gmail.com" \
          --username "nanoyaki" \
          --password "$(cat ${config.sops.secrets."forgejo/users/nanoyaki".path})" \
          || true

        if ! forgejo admin auth list | grep -q PocketID; then
          forgejo admin auth add-oauth \
            --name "PocketID" \
            --provider "openidConnect" \
            --key "$(cat ${config.sops.secrets."forgejo/oidc/id".path})" \
            --secret "$(cat ${config.sops.secrets."forgejo/oidc/secret".path})" \
            --auto-discover-url "https://id.theless.one/.well-known/openid-configuration" \
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
