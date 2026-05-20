{ preferNewerOverlay, ... }:

{
  perSystem =
    { lib, pkgs, ... }:

    {
      packages.prowlarr = pkgs.prowlarr.overrideAttrs (
        finalAttrs: prevAttrs:
        let
          nugetDeps = map pkgs.dotnetCorePackages.fetchNupkg (lib.importJSON ./deps.json);
        in

        {
          pname = "prowlarr";
          version = "2.3.7.5365";

          src = pkgs.applyPatches {
            src = pkgs.fetchgit {
              url = "https://github.com/Prowlarr/Prowlarr.git";
              rev = "v${finalAttrs.version}";
              fetchSubmodules = false;
              deepClone = false;
              leaveDotGit = false;
              sparseCheckout = [ ];
              sha256 = "sha256-NWlf3KUBnwu9I0Z4kNiRi3Ade7srNsB5qQJJ9/ril9E=";
            };

            postPatch = ''
              mv src/NuGet.config NuGet.Config
            '';
          };

          buildInputs = nugetDeps ++ prevAttrs.buildInputs;

          yarnOfflineCache = pkgs.fetchYarnDeps {
            yarnLock = finalAttrs.src + "/yarn.lock";
            hash = "sha256-FYLfOR5gm9lg1F8RGyDN6MkFAcaxWIdIxd/IDBVUMUQ=";
          };
        }
      );
    };

  flake.overlays.prowlarr = preferNewerOverlay "prowlarr";
}
