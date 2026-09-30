{ preferNewerOverlay, ... }:

{
  perSystem =
    { pkgs, ... }:

    {
      packages.suwayomi-webui = pkgs.callPackage (
        {
          lib,
          stdenvNoCC,
          fetchFromGitHub,
          fetchPnpmDeps,
          pnpm_11,
          pnpmConfigHook,
          pnpmBuildHook,
          nodejs_24,
          husky,
          tsx,
        }:

        stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "suwayomi-webui";
          version = "20260726.01";
          revision = "3379";

          __structuredAttrs = true;
          strictDeps = true;

          src = fetchFromGitHub {
            owner = "Suwayomi";
            repo = "Suwayomi-WebUI";
            tag = "v${finalAttrs.version}";
            sha256 = "sha256-1eYVgoYSBX2ZHTZUXi0TN17m1UresEfdTc4Sq8rykbU=";
          };

          pnpmDeps = fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            pnpm = pnpm_11;
            fetcherVersion = 4;
            hash = "sha256-hFl9tcfQkpRYnxb1/K+c0OiRVqCEwhLgEZvuq0Tc9fA=";
          };

          nativeBuildInputs = [
            pnpmConfigHook
            pnpmBuildHook
            pnpm_11

            nodejs_24
            husky
            tsx
          ];

          postPatch = ''
            substituteInPlace package.json \
              --replace-fail "project" "suwayomi-webui"
          '';

          postBuild = ''
            touch build/revision
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/suwayomi-webui
            cp -a build $out/share/suwayomi-webui

            runHook postInstall
          '';

          meta = {
            description = "The client for Suwayomi-Server";
            homepage = "https://github.com/Suwayomi/Suwayomi-WebUI";
            downloadPage = "https://github.com/Suwayomi/Suwayomi-WebUI/releases/";
            changelog = "https://github.com/Suwayomi/Suwayomi-WebUI/releases/tag/v${finalAttrs.version}";
            license = lib.licenses.mpl20;
            inherit (nodejs_24.meta) platforms;
            maintainers = with lib.maintainers; [ nanoyaki ];
          };
        })
      ) { };
    };

  flake.overlays.suwayomi-webui = preferNewerOverlay "suwayomi-webui";
}
