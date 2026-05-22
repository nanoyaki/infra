{
  flake.nixosModules.sentinel-ddns =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    {
      sops = {
        secrets = {
          "porkbun/secret-api-key" = { };
          "porkbun/api-key" = { };
          "porkbun/pds-secret-api-key" = { };
          "porkbun/pds-api-key" = { };
        };

        templates."oink.json".restartUnits = [ "oink.service" ];
        templates."oink.json".content = builtins.toJSON {
          global = {
            secretapikey = config.sops.placeholder."porkbun/pds-secret-api-key";
            apikey = config.sops.placeholder."porkbun/pds-api-key";
            interval = 900;
            ttl = 600;
          };

          domains = [
            {
              secretapikey = config.sops.placeholder."porkbun/secret-api-key";
              apikey = config.sops.placeholder."porkbun/api-key";
              domain = "theless.one";
              subdomain = "";
              skipIPv6 = true;
            }
            {
              secretapikey = config.sops.placeholder."porkbun/secret-api-key";
              apikey = config.sops.placeholder."porkbun/api-key";
              domain = "theless.one";
              subdomain = "binarycache";
              skipIPv6 = true;
            }
            {
              secretapikey = config.sops.placeholder."porkbun/secret-api-key";
              apikey = config.sops.placeholder."porkbun/api-key";
              domain = "theless.one";
              subdomain = "de01";
              skipIPv6 = true;
            }
            {
              domain = "nanoyaki.space";
              subdomain = "";
            }
            {
              domain = "nanoyaki.space";
              subdomain = "*";
            }
          ];
        };
      };

      systemd.services.oink = {
        description = "Dynamic DNS client for Porkbun";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          LoadCredential = "oink.json:${config.sops.templates."oink.json".path}";
          ExecStart = "${lib.getExe pkgs.oink} -c \${CREDENTIALS_DIRECTORY}/oink.json -v";
          Restart = "always";
          Type = "simple";

          # Hardening
          DynamicUser = true;
          CapabilityBoundingSet = "";
          SystemCallFilter = [ "@system-service" ];

          NoNewPrivileges = true;
          ProtectClock = true;
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          RestrictRealtime = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          MemoryDenyWriteExecute = true;
          ProtectHostname = true;

          ProtectSystem = "strict";
          PrivateTmp = true;
          ProtectHome = true;
          PrivateDevices = true;
          ProtectControlGroups = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectProc = "invisible";
        };
      };
    };
}
