{ preferNewerOverlay, ... }:

{
  perSystem =
    { pkgs, config, ... }:

    {
      packages.shoko = pkgs.callPackage (
        {
          lib,
          buildDotnetModule,
          fetchFromGitHub,
          dotnet-sdk_10,
          dotnet-aspnetcore_10,
          mediainfo,
          rhash,
          replaceVars,
          avdump,
        }:

        buildDotnetModule (finalAttrs: {
          pname = "shoko";
          version = "6.0.0";

          src = fetchFromGitHub {
            owner = "ShokoAnime";
            repo = "ShokoServer";
            tag = "v6.0.0-dev.114";
            hash = "sha256-x7WK8hppFwf3aNR3BcLOhG3+MkZYrKcu5cu+oXECwKg=";
          };

          patches = [
            (replaceVars ./avdump.patch { inherit avdump; })
          ];

          dotnet-sdk = dotnet-sdk_10;
          dotnet-runtime = dotnet-aspnetcore_10;

          nugetDeps = ./deps.json;
          projectFile = "Shoko.CLI/Shoko.CLI.csproj";
          dotnetBuildFlags = "/p:InformationalVersion=\"channel=dev,tag=${finalAttrs.version}-dev.114\"";
          dotnetFlags = "/p:TargetFramework=net10.0";

          executables = [ "Shoko.CLI" ];
          makeWrapperArgs = [
            "--prefix"
            "PATH"
            ":"
            "${mediainfo}/bin"
          ];
          runtimeDeps = [ rhash ];

          meta = {
            homepage = "https://github.com/ShokoAnime/ShokoServer";
            changelog = "https://github.com/ShokoAnime/ShokoServer/releases/tag/v${finalAttrs.version}-dev.114";
            description = "Backend for the Shoko anime management system";
            license = lib.licenses.mit;
            mainProgram = "Shoko.CLI";
            maintainers = [ lib.maintainers.nanoyaki ];
            inherit (dotnet-sdk_10.meta) platforms;
          };
        })
      ) { inherit (config.packages) avdump; };
    };

  flake.overlays.shoko = preferNewerOverlay "shoko";
}
