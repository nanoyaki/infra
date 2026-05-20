{ preferNewerOverlay, ... }:

{
  perSystem =
    { pkgs, ... }:

    {
      packages.shoko-webui = pkgs.callPackage (
        {
          lib,
          stdenvNoCC,
          fetchFromGitHub,
          nodejs,
          pnpm,
          pnpmConfigHook,
          fetchPnpmDeps,
          shoko,
          nix-update-script,
        }:
        stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "shoko-webui";
          version = "2.6.0";

          src = fetchFromGitHub {
            owner = "ShokoAnime";
            repo = "Shoko-Webui";
            tag = "v${finalAttrs.version}-dev.26";
            hash = "sha256-/LyBlAujyFgwRnCARTcBukzez0+NvIjNrxqAW7cFMLo=";
          };

          # Avoid requiring git as a build time dependency. It's used for version
          # checking in the updater, which shouldn't be used if the webui is managed
          # declaratively anyway.
          patches = [ ./no-commit-hash.patch ];

          nativeBuildInputs = [
            nodejs
            pnpmConfigHook
            pnpm
          ];

          pnpmDeps = fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            inherit pnpm;
            fetcherVersion = 3;
            hash = "sha256-1GZ0OC6RQg8VpEc7gVnfW/SRqZCOOhrt3nAU949y3Ag=";
          };

          buildPhase = ''
            runHook preBuild
            pnpm build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            cp -r dist $out
            runHook postInstall
          '';

          passthru.updateScript = nix-update-script {
            extraArgs = [
              "-F"
              "--version=branch"
            ];
          };

          meta = {
            homepage = "https://github.com/ShokoAnime/Shoko-WebUI";
            changelog = "https://github.com/ShokoAnime/Shoko-WebUI/releases/tag/v${finalAttrs.version}-dev.26";
            description = "Web-based frontend for the Shoko anime management system";
            maintainers = with lib.maintainers; [
              diniamo
              nanoyaki
            ];
            inherit (shoko.meta) license platforms;
          };
        })
      ) { };
    };

  flake.overlays.shoko-webui = preferNewerOverlay "shoko-webui";
}
