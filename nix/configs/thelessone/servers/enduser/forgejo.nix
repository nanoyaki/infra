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
      };

      sops.templates."kikyo.env".file = pkgs.writeEnv "kikyo.env.template" {
        TOKEN = config.sops.placeholder."forgejo/kikyo";
      };

      sops.templates."syakuyaku.env".file = pkgs.writeEnv "syakuyaku.env.template" {
        TOKEN = config.sops.placeholder."forgejo/syakuyaku";
      };

      sops.templates."botan.env".file = pkgs.writeEnv "botan.env.template" {
        TOKEN = config.sops.placeholder."forgejo/botan";
        REGISTRY_AUTH_FILE = config.sops.templates."auth.json".path;
      };

      sops.templates."kigiku.env".file = pkgs.writeEnv "kigiku.env.template" {
        TOKEN = config.sops.placeholder."forgejo/kigiku";
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

              nix
              openssh
              statix
              dix
              inotify-tools
              nh
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
            DISABLE_REGISTRATION = true;
            ENABLE_NOTIFY_MAIL = true;
          };

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

      mailserver.loginAccounts."git@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/git".path;
      };

      services.borgbackup.jobs.forgejo = {
        repo = "thelessone-borg@10.0.0.6:forgejo";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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

      thelessone.caddy.vHost."git.theless.one".proxy.port = cfg.settings.server.HTTP_PORT;

      sops.secrets."forgejo/users/nanoyaki".owner = cfg.user;
      systemd.services.forgejo.preStart = ''
        ${lib.getExe cfg.package} admin user create \
          --admin \
          --email "hanakretzer@gmail.com" \
          --username "nanoyaki" \
          --password "$(cat ${config.sops.secrets."forgejo/users/nanoyaki".path})" \
          || true
      '';
    };
}
