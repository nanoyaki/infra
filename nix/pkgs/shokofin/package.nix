{ preferNewerOverlay, ... }:

{
  perSystem =
    { pkgs, ... }:

    {
      packages.shokofin = pkgs.callPackage (
        {
          lib,
          buildDotnetModule,
          fetchFromGitHub,
          dotnet-sdk_9,
          dotnet-aspnetcore_9,
        }:

        buildDotnetModule (finalAttrs: {
          pname = "shokofin";
          version = "6.0.5";

          # __structuredAttrs = true;
          # strictDeps = true;

          src = fetchFromGitHub {
            owner = "ShokoAnime";
            repo = "Shokofin";
            tag = "v${finalAttrs.version}";
            hash = "sha256-vAbhbMnnfnFkBIramuRccuSvDb+WJKGG6hOX9V5luNc=";
          };

          dotnet-sdk = dotnet-sdk_9;
          dotnet-runtime = dotnet-aspnetcore_9;

          nugetDeps = ./deps.json;
          projectFile = "Shokofin/Shokofin.csproj";
          dotnetBuildFlags = "/p:InformationalVersion=\"channel=dev,tag=${finalAttrs.version}\"";
          dotnetFlags = "/p:TargetFramework=net9.0";

          executables = [ ];

          meta = {
            homepage = "https://github.com/ShokoAnime/Shokofin";
            changelog = "https://github.com/ShokoAnime/Shokofin/releases/tag/v${finalAttrs.version}";
            description = "Shoko anime Jellyfin integration plugin";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.nanoyaki ];
            inherit (dotnet-sdk_9.meta) platforms;
          };
        })
      ) { };
    };

  flake.overlays.shokofin = preferNewerOverlay "shokofin";
}
