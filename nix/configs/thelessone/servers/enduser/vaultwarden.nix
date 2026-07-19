{
  flake.nixosModules.thelessone-vaultwarden =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config)
        prt
        dmn
        tpl
        plh
        ;
    in

    {
      prt.vaultwarden = 8011;
      dmn.vaultwarden = "vaultwarden.theless.one";

      # sec.vaultwarden-admin-token = { };

      tpl."vaultwarden.env" = {
        file = pkgs.writeEnv "vaultwarden.env.template" {
          SMTP_PASSWORD = plh.no-reply-password;
          # ADMIN_TOKEN= "'${plh.vaultwarden-admin-token}'";
        };
        restartUnits = [ "vaultwarden.service" ];
      };

      systemd.services.vaultwarden.wantedBy = lib.mkForce [ "server-services.target" ];
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        backupDir = "/var/backup/vaultwarden";

        config = {
          DOMAIN = "https://${dmn.vaultwarden}";

          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = prt.vaultwarden;

          SMTP_HOST = dmn.mail;
          SMTP_PORT = prt.smtp-tls;
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

        environmentFile = tpl."vaultwarden.env".path;
      };

      thelessone.caddy.vHost.${dmn.vaultwarden}.proxy.port = prt.vaultwarden;

      # FIXME: remote backup
      thelessone.backups.vaultwarden.paths = [
        "/var/lib/vaultwarden"
        config.services.vaultwarden.backupDir
      ];
    };
}
