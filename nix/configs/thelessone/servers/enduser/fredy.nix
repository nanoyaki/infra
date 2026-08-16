{ selfOverlay, ... }:

{
  flake.nixosModules.thelessone-fredy =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config) dmn prt;
    in

    {
      prt.fredy = 9998;
      dmn.fredy = "fredy.theless.one";

      thelessone.caddy.vHost.${dmn.fredy} = {
        proxy.port = prt.fredy;
        useTailnet = true;
      };

      users.users.fredy = {
        isSystemUser = true;
        group = "fredy";
      };

      users.groups.fredy = { };

      systemd.services.fredy = {
        wantedBy = [ "server-services.target" ];
        after = [ "network.target" ];

        environment.HOME = "/var/lib/fredy";

        confinement.enable = true;
        confinement.mode = "chroot-only";

        serviceConfig = {
          Type = "simple";
          ExecStart = lib.getExe pkgs.fredy;
          StateDirectory = "fredy";
          CacheDirectory = "fredy";
          WorkingDirectory = "/var/cache/fredy";

          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          PrivateTmp = true;
          PrivateMounts = true;
          PrivateDevices = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          # Nodejs...
          MemoryDenyWriteExecute = false;

          ProcSubset = "pid";
          ProtectProc = "invisible";

          NoNewPrivileges = true;

          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];

          UMask = "0027";
          User = "fredy";
          Group = "fredy";

          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
            "AF_NETLINK"
          ];

          BindPaths = [
            "${pkgs.fredy}/lib/node_modules/fredy:/var/cache/fredy"
            "/var/lib/fredy:/var/cache/fredy/conf"
            "/var/lib/fredy:/var/cache/fredy/db"
          ];
        };
      };
    };

  perSystem =
    {
      inputs',
      pkgs,
      config,
      ...
    }:

    let
      cloakbrowser = inputs'.cloakbrowser.packages.cloakbrowserChromium;
    in

    {
      packages.fredy-cloakbrowser = pkgs.symlinkJoin {
        name = "fredy-${cloakbrowser.name}";
        paths = [
          "${cloakbrowser}/lib/cloakbrowser"
          "${cloakbrowser}/bin"
        ];
      };

      packages.fredy = pkgs.callPackage (
        {
          lib,
          stdenv,
          fetchFromGitHub,
          fetchYarnDeps,
          yarnConfigHook,
          yarnBuildHook,
          yarnInstallHook,
          nodejs,
          makeWrapper,
        }:

        stdenv.mkDerivation (finalAttrs: {
          pname = "fredy";
          version = "26.2.0";

          src = fetchFromGitHub {
            owner = "orangecoding";
            repo = "fredy";
            tag = finalAttrs.version;
            hash = "sha256-xpA87/2vjjpGUQWMYot5Y/x1KAQfCmP1BgphU8Ihwrg=";
          };

          yarnOfflineCache = fetchYarnDeps {
            yarnLock = finalAttrs.src + "/yarn.lock";
            hash = "sha256-PAYIL4Xl2haKCoD8EfTtjTfTVgXjV4bfYapOG9g8Zxg=";
          };

          nativeBuildInputs = [
            yarnConfigHook
            yarnBuildHook
            yarnInstallHook
            # Needed for executing package.json scripts
            nodejs
            makeWrapper
          ];

          yarnBuildScript = "build:frontend";

          postInstall = ''
            makeWrapper ${lib.getExe nodejs} $out/bin/fredy \
              --set NODE_ENV production \
              --set CLOAKBROWSER_BINARY_PATH "${config.packages.fredy-cloakbrowser}/cloakbrowser-chrome" \
              --add-flags "$out/lib/node_modules/fredy/index.js" \
              --run 'if [ -z "$INVOCATION_ID" ]; then cd "'"$out"'/lib/node_modules/fredy"; fi'
          '';

          meta = {
            description = "Self-Hosted Real Estate Finder for Germany";
            license = lib.licenses.asl20;
            maintainers = [ lib.maintainers.nanoyaki ];
            mainProgram = "fredy";
          };
        })
      ) { };
    };

  flake.overlays.fredy = selfOverlay "fredy";
}
