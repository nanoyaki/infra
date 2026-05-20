{ withSystem, ... }:

{
  perSystem =
    { pkgs, ... }:

    {
      packages.avdump = pkgs.callPackage (
        {
          lib,
          buildDotnetModule,
          stdenv,
          fetchFromGitHub,
          dotnet-sdk_10,
          dotnet-runtime,
          libmediainfo,
          runCommand,
        }:

        buildDotnetModule (finalAttrs: {
          pname = "avdump";
          version = "0.1.0";

          src = fetchFromGitHub {
            owner = "DvdKhl";
            repo = "AVDump3";
            rev = "36559da1646afa30481537bce41a5a155ef54f8c";
            hash = "sha256-+3sqN8JkJwxIXwREv7l1iBh7weWRS3deOhvdc3cpiPw=";
          };

          avdumpNativeLib = stdenv.mkDerivation (cFinalAttrs: {
            inherit (finalAttrs)
              pname
              version
              src
              ;

            sourceRoot = "${cFinalAttrs.src.name}/AVDump3NativeLib";

            postPatch = ''
              substituteInPlace Makefile \
                --replace-fail 'CC = $(ARCH)-linux-gnu-gcc' \
                  'CC = gcc'
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/lib
              mv AVDump3NativeLib.so $out/lib

              runHook postInstall
            '';
          });

          patches = [ ./revision.patch ];

          dotnet-sdk = dotnet-sdk_10;
          inherit dotnet-runtime;

          nugetDeps = ./deps.json;
          projectFile = "AVDump3CL/AVDump3CL.csproj";
          runtimeDeps = [
            finalAttrs.avdumpNativeLib
            (runCommand "MediaInfo" { } ''
              mkdir -p $out/lib
              ln -s ${libmediainfo}/lib/libmediainfo.so $out/lib/MediaInfo.so
            '')
          ];

          executables = [ "AVDump3CL" ];

          meta = {
            homepage = "https://github.com/DvdKhl/AVDump3";
            description = "Provide meta information about multi media files and their file hashes by selectable report formats";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ nanoyaki ];
            platforms = lib.platforms.linux;
            mainProgram = "AVDump3CL";
          };
        })
      ) { };
    };

  flake.overlays.avdump =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) avdump;
      }
    );
}
