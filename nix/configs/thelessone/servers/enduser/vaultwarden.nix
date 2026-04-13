{
  flake.nixosModules.thelessone-vaultwarden =
    { pkgs, config, ... }:

    {
      sops.secrets = {
        vaultwarden-smtp-password = { };
        vaultwarden-admin-token = { };
        "mailserver/vaultwarden" = { };
      };

      sops.templates."vaultwarden.env" = {
        file = pkgs.writeEnv "vaultwarden.env.template" {
          SMTP_PASSWORD = config.sops.placeholder.vaultwarden-smtp-password;
          # ADMIN_TOKEN= "'${config.sops.placeholder.vaultwarden-admin-token}'";
        };
        restartUnits = [ "vaultwarden.service" ];
      };

      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        backupDir = "/var/backup/vaultwarden";

        config = {
          DOMAIN = "https://vaultwarden.theless.one";

          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;

          SMTP_HOST = "mail.theless.one";
          SMTP_PORT = 465;
          SMTP_SECURITY = "force_tls";
          SMTP_DEBUG = true;

          SMTP_USERNAME = "vaultwarden@theless.one";
          SMTP_FROM = "vaultwarden@theless.one";
          SMTP_FROM_NAME = "Vaultwarden Theless.one";

          SIGNUPS_ALLOWED = false;
          SIGNUPS_VERIFY = true;
          REQUIRE_DEVICE_EMAIL = true;

          ORG_CREATION_USERS = "hanakretzer@gmail.com";
        };

        environmentFile = config.sops.templates."vaultwarden.env".path;
      };

      mailserver.accounts."vaultwarden@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/vaultwarden".path;
      };

      services.newt.blueprint.public-resources.vaultwarden = {
        name = "Vaultwarden";
        protocol = "http";
        full-domain = "vaultwarden.theless.one";
        host-header = "vaultwarden.theless.one";
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            port = config.services.vaultwarden.config.ROCKET_PORT;
            method = "http";
            path = "/";
            path-match = "prefix";
          }
        ];
      };

      # FIXME: remote backup

      # sops.secrets = {
      #   "restic/100-64-64-6" = { };
      #   "restic/vaultwarden-remote" = { };
      # };

      # sops.templates."restic-vauldwarden-repo.txt".content = ''
      #   rest:https://restic:${
      #     config.sops.placeholder."restic/100-64-64-6"
      #   }@restic.hanakretzer.de/vaultwarden-thelessone
      # '';

      # config'.restic.backups.vaultwarden-remote = {
      #   repositoryFile = config.sops.templates."restic-vauldwarden-repo.txt".path;
      #   passwordFile = config.sops.secrets."restic/vaultwarden-remote".path;

      #   paths = [
      #     "/var/lib/vaultwarden"
      #     config.services.vaultwarden.backupDir
      #   ];

      #   timerConfig.OnCalendar = "*-*-* 00/3:00:00";
      # };

      systemd.services.borgbackup-job-vaultwarden.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.vaultwarden = {
        repo = "/mnt/raid/borgbackup/vaultwarden";
        doInit = true;

        paths = "/var";
        patterns = [
          "+ /var/lib/vaultwarden"
          "+ ${config.services.vaultwarden.backupDir}"
          "- **"
        ];

        encryption.mode = "none";
        compression = "zstd";

        startAt = "*-*-* 00/3:00:00";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 14;
          weekly = 12;
          monthly = -1;
        };
      };
    };
}
