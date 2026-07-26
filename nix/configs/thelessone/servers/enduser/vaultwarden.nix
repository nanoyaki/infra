{ withSystem, ... }:

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

  perSystem = { lib, pkgs, ... }: {
    packages.vaultwarden =
      if lib.versionAtLeast pkgs.vaultwarden.version "1.37.0" then
        pkgs.vaultwarden
      else
        pkgs.vaultwarden.overrideAttrs (
          finalAttrs: _prevAttrs: {
            version = "1.37.0";
            src = pkgs.fetchFromGitHub {
              owner = "dani-garcia";
              repo = "vaultwarden";
              tag = finalAttrs.version;
              hash = "sha256-7l9tIBCfk8DeQDtIoENnjGUzVWJM3aZxw6eA+YaktlM=";
            };

            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              inherit (finalAttrs) src;
              hash = "sha256-sza4ZQz2+QJJJ03Upt6sGXAv+1VPImN2qZHXaTSALFQ=";
            };
          }
        );
  };

  flake.overlays.vaultwarden =
    _: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }: {
        inherit (config.packages) vaultwarden;
      }
    );
}
