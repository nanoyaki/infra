{ withSystem, ... }:

{
  flake.nixosModules.thelessone-seerr =
    { lib, config, ... }:

    {
      systemd.services.seerr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.seerr.enable = true;

      thelessone.caddy.vHost."jellyseerr.theless.one" = {
        proxy = { inherit (config.services.seerr) port; };
        useTailnet = true;
      };

      systemd.services.borgbackup-job-jellyseerr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.jellyseerr = {
        repo = "/mnt/raid/borgbackup/jellyseerr";
        doInit = true;

        paths = "/var/lib/private/jellyseerr";

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
    };

  perSystem =
    { pkgs, ... }:

    {
      packages.seerr = pkgs.seerr.overrideAttrs (
        finalAttrs: _: {
          version = "preview-new-oidc";
          src = pkgs.fetchFromGitHub {
            owner = "seerr-team";
            repo = "seerr";
            tag = finalAttrs.version;
            hash = "sha256-bfNRUlMjKmxv0uvvjktQpCvCKl26C2Krs30ykkIRz7I=";
          };

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            pnpm = pkgs.pnpm_10.override { nodejs = pkgs.nodejs_22; };
            fetcherVersion = 3;
            hash = "sha256-AvbTO6hBK/NB8uS6oLTgbgrARabvsFjiThqg2aTn1Fs=";
          };
        }
      );
    };

  flake.overlays.seerr =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) seerr;
      }
    );
}
