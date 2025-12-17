{ pkgs, config, ... }:

let
  domain = "vaultwarden.theless.one";
in

{
  sops.secrets = {
    vaultwarden-smtp-password = { };
    vaultwarden-admin-token = { };
  };
  sops.templates."vaultwarden.env" = {
    file = (pkgs.formats.keyValue { }).generate "vaultwarden.env.template" {
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
      DOMAIN = "https://${domain}";

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

  config'.caddy.vHost.${domain}.proxy.port = config.services.vaultwarden.config.ROCKET_PORT;

  sops.secrets = {
    "restic/100-64-64-6" = { };
    "restic/vaultwarden-remote" = { };
  };

  sops.templates."restic-vauldwarden-repo.txt".content = ''
    rest:https://restic:${
      config.sops.placeholder."restic/100-64-64-6"
    }@restic.hanakretzer.de/vaultwarden-thelessone
  '';

  config'.restic.backups.vaultwarden-remote = {
    repositoryFile = config.sops.templates."restic-vauldwarden-repo.txt".path;
    passwordFile = config.sops.secrets."restic/vaultwarden-remote".path;

    paths = [
      "/var/lib/vaultwarden"
      config.services.vaultwarden.backupDir
    ];

    timerConfig.OnCalendar = "*-*-* 00/3:00:00";
  };

  services.borgbackup.jobs.vaultwarden = {
    repo = "thelessone-borg@10.0.0.6:vaultwarden";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
}
