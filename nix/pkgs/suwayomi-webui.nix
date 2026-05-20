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
          fetchYarnDeps,
          yarnConfigHook,
          yarnInstallHook,
          nodejs_24,
          husky,
          tsx,
        }:

        stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "suwayomi-webui";
          version = "20260509.01";
          revision = "3147";

          __structuredAttrs = true;
          strictDeps = true;

          src = fetchFromGitHub {
            owner = "Suwayomi";
            repo = "Suwayomi-WebUI";
            tag = "v${finalAttrs.version}";
            sha256 = "sha256-CA3ttZRgUF8ISfpYyFePvP9vx17a0+ls0Bqz211qHzs=";
          };

          yarnOfflineCache = fetchYarnDeps {
            yarnLock = finalAttrs.src + "/yarn.lock";
            hash = "sha256-GAvK4ESkbWSsCbMeC0vOekGGbzaj2X8MVhFiLk/sAV8=";
          };

          nativeBuildInputs = [
            yarnConfigHook
            yarnInstallHook

            nodejs_24
            husky
            tsx
          ];

          postPatch = ''
            substituteInPlace package.json \
              --replace-fail "project" "suwayomi-webui"
          '';

          buildPhase = ''
            runHook preBuild

            yarn --offline setup-env-files

            patchShebangs node_modules/vite/bin/vite.js
            node_modules/vite/bin/vite.js build

            echo "r${finalAttrs.revision}" > build/revision
            yarn --offline build-md5

            runHook postBuild
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
