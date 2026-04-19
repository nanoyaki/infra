{ withSystem, ... }:

{
  flake.nixosModules.thelessone-oxicloud =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      port = 8086;
      dataDir = "/var/lib/oxicloud";

      plh = config.sops.placeholder;
    in

    {
      sops.secrets = {
        "oxicloud/oidc-id" = { };
        "oxicloud/oidc-secret" = { };
        "oxicloud/jwt-secret" = { };
      };

      sops.templates."oxicloud.env".file = pkgs.writeEnv "oxicloud.env.template" {
        OXICLOUD_JWT_SECRET = plh."oxicloud/jwt-secret";
        OXICLOUD_OIDC_CLIENT_ID = plh."oxicloud/oidc-id";
        OXICLOUD_OIDC_CLIENT_SECRET = plh."oxicloud/oidc-secret";
      };

      services.postgresql = {
        ensureUsers = [
          {
            name = "oxicloud";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [ "oxicloud" ];
      };

      users.groups.oxicloud = { };
      users.users.oxicloud = {
        isSystemUser = true;
        group = "oxicloud";
      };

      systemd.tmpfiles.settings."10-oxicloud"."${dataDir}/storage".d = {
        user = "oxicloud";
        group = "oxicloud";
        mode = "750";
      };

      systemd.services.oxicloud = {
        description = "Oxicloud";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "postgresql.service"
        ];

        environment = {
          OXICLOUD_STATIC_PATH = "${pkgs.oxicloud}/share/oxicloud/static";
          OXICLOUD_STORAGE_PATH = "${dataDir}/storage";
          OXICLOUD_SERVER_HOST = "127.0.0.1";
          OXICLOUD_SERVER_PORT = toString port;
          OXICLOUD_BASE_URL = "https://cloud.theless.one";

          OXICLOUD_DB_CONNECTION_STRING = "postgres:///oxicloud?host=/run/postgresql";

          OXICLOUD_ENABLE_FILE_SHARING = "true";
          OXICLOUD_ENABLE_TRASH = "true";
          OXICLOUD_ENABLE_SEARCH = "true";
          OXICLOUD_WOPI_ENABLED = "false";

          OXICLOUD_OIDC_ENABLED = "true";
          OXICLOUD_OIDC_DISABLE_PASSWORD_LOGIN = "true";
          OXICLOUD_OIDC_AUTO_PROVISION = "true";
          OXICLOUD_OIDC_PROVIDER_NAME = "Pocket ID";
          OXICLOUD_OIDC_ISSUER_URL = "https://id.theless.one";
          OXICLOUD_OIDC_FRONTEND_URL = "https://cloud.theless.one";
          OXICLOUD_OIDC_SCOPES = "openid profile email groups";
          OXICLOUD_OIDC_ADMIN_GROUPS = "oxicloud_admin";
        };

        serviceConfig = {
          EnvironmentFile = config.sops.templates."oxicloud.env".path;
          Type = "simple";
          ExecStart = lib.getExe pkgs.oxicloud;
          User = "oxicloud";
          Group = "oxicloud";

          UMask = "0027";
          StateDirectory = "oxicloud";
          WorkingDirectory = dataDir;
          ReadWritePaths = [ dataDir ];

          DeviceAllow = [ "" ];
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];
          CapabilityBoundingSet = "";
          NoNewPrivileges = true;

          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          RestrictRealtime = true;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
          MemoryDenyWriteExecute = true;

          ProtectHostname = true;
          ProtectClock = true;
          ProtectSystem = "strict";
          PrivateTmp = true;
          ProtectHome = true;
          PrivateDevices = true;
          ProtectControlGroups = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectProc = "invisible";
          RemoveIPC = true;
        };
      };

      thelessone.caddy.vHost."cloud.theless.one" = {
        proxy = { inherit port; };
        pangolin.name = "Oxicloud";
      };
    };

  perSystem =
    { pkgs, ... }:

    {
      packages.oxicloud = pkgs.callPackage (
        {
          lib,
          rustPlatform,
          fetchFromGitHub,
          openssl,
        }:

        rustPlatform.buildRustPackage (finalAttrs: {
          pname = "oxicloud";
          version = "5288e692f0f9865323cc875127a5d39d45d118eb";

          src = fetchFromGitHub {
            owner = "DioCrafts";
            repo = "OxiCloud";
            rev = finalAttrs.version;
            hash = "sha256-5U0P19LqfbwHu8FLtqGMRckyxcAewqKXtDR+wGnLQIQ=";
          };

          postPatch = ''
            substituteInPlace src/main.rs \
              --replace-fail \
                '"./static/locales"' \
                'std::format!("{}/locales", config.static_path.display())'
          '';

          cargoHash = "sha256-lBx5wC3yCweIr15f+zMyTE7/qvZKN3rNIsF5sYFIWIs=";

          buildInputs = [
            openssl
          ];

          postInstall = ''
            mkdir -p $out/share/oxicloud

            cp -a static-dist $out/share/oxicloud/static
          '';

          doCheck = false;

          meta = {
            mainProgram = "oxicloud";
            description = "Self-hosted cloud storage, calendar & contacts.";
            platforms = lib.platforms.linux;
            maintainers = with lib.maintainers; [ nanoyaki ];
          };
        })
      ) { };
    };

  flake.overlays.oxicloud =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) oxicloud;
      }
    );
}
