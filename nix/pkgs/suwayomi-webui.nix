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
          pnpm,
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
            inherit pnpm;
            fetcherVersion = 4;
            hash = "sha256-tbaNDI2kJKwriZGaSgqQAKPAB8ser53Nc6J4Jp6aqFY=";
          };

          nativeBuildInputs = [
            pnpmConfigHook
            pnpmBuildHook
            pnpm

            nodejs_24
            husky
            tsx
          ];

          postPatch = ''
            substituteInPlace package.json \
              --replace-fail "project" "suwayomi-webui"

            patchShebangs node_modules/vite/bin/vite.js
          '';

          preBuild = ''
            pnpm setup-env-files
          '';

          postBuild = ''
            echo "r${finalAttrs.revision}" > build/revision
            pnpm build-md5
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/suwayomi-server
            cp -a build $out/share/suwayomi-webui
            mv buildZip/md5sum $out/share/suwayomi-server

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
