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
    };

    templates."oink.json".content = builtins.toJSON {
      global = {
        secretapikey = config.sops.placeholder."porkbun/secret-api-key";
        apikey = config.sops.placeholder."porkbun/api-key";
        interval = 900;
        ttl = 600;
      };

      domains = [
        {
          domain = "theless.one";
          subdomain = "";
        }
        {
          domain = "theless.one";
          subdomain = "*";
        }
        {
          domain = "theless.one";
          subdomain = "de01";
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
}
