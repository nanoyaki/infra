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

      thelessone.backups.jellyseerr.paths = [ "/var/lib/private/jellyseerr" ];
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
            hash = "sha256-YPpicQlArAqWnRbUbtUYlwTJk0AGxcaeQmaYNT0vogo=";
          };

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            pnpm = pkgs.pnpm_10.override { nodejs-slim = pkgs.nodejs_22; };
            fetcherVersion = 3;
            hash = "sha256-7nBkeXGJfDRSvNesOjOK+Mtzp6SlBvbytyfsQl9eh/Y=";
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
