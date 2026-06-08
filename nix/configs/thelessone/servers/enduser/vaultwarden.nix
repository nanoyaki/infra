{
  flake.nixosModules.thelessone-vaultwarden =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    {
      sops.secrets = {
        vaultwarden-smtp-password = { };
        vaultwarden-admin-token = { };
        "mailserver/vaultwarden" = { };
      };

      sops.templates."vaultwarden.env" = {
        file = pkgs.writeEnv "vaultwarden.env.template" {
          SMTP_PASSWORD = config.sops.placeholder.no-reply-password;
          # ADMIN_TOKEN= "'${config.sops.placeholder.vaultwarden-admin-token}'";
        };
        restartUnits = [ "vaultwarden.service" ];
      };

      systemd.services.vaultwarden.wantedBy = lib.mkForce [ "server-services.target" ];
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

          SMTP_USERNAME = "no-reply@theless.one";
          SMTP_FROM = "no-reply@theless.one";
          SMTP_FROM_NAME = "Vaultwarden Theless.one";

          SIGNUPS_ALLOWED = false;
          SIGNUPS_VERIFY = true;
          REQUIRE_DEVICE_EMAIL = true;

          ORG_CREATION_USERS = "hanakretzer@gmail.com";
        };

        environmentFile = config.sops.templates."vaultwarden.env".path;
      };

      thelessone.caddy.vHost."vaultwarden.theless.one".proxy.port =
        config.services.vaultwarden.config.ROCKET_PORT;

      # FIXME: remote backup
      thelessone.backups.vaultwarden.paths = [
        "/var/lib/vaultwarden"
        config.services.vaultwarden.backupDir
      ];
    };
}
