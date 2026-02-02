{ inputs, ... }:

{
  flake.nixosModules.thelessone-ddns =
    { pkgs, config, ... }:

    {
      sops.secrets."namecheap/vappie.space" = { };

      systemd.services."namecheap-ddns-vappie.space" = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        path = with pkgs; [
          coreutils-full
          curl
        ];

        script = ''
          set -f

          domain="vappie.space"
          subdomains="* @"
          password="$(cat $CREDENTIALS_DIRECTORY/password)"
          ip="$(curl "https://am.i.mullvad.net/ip" --fail)"

          for subdomain in ''${subdomains}; do
            curl "https://dynamicdns.park-your-domain.com/update?host=$subdomain&domain=$domain&password=$password&ip=$ip" --fail
          done
        '';

        startAt = "hourly";

        serviceConfig = {
          LoadCredential = "password:${config.sops.secrets."namecheap/vappie.space".path}";
          Type = "oneshot";
          Restart = "no";

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

      sops.templates."oink.json".content = builtins.toJSON {
        global = {
          secretapikey = config.sops.placeholder."porkbun/secret-api-key";
          apikey = config.sops.placeholder."porkbun/api-key";
          interval = 900;
          ttl = 600;
        };

        domains = [
          {
            secretapikey = config.sops.placeholder."porkbun-nano/secret-api-key";
            apikey = config.sops.placeholder."porkbun-nano/api-key";
            domain = "nanoyaki.space";
            subdomain = "";
          }
          {
            secretapikey = config.sops.placeholder."porkbun-nano/secret-api-key";
            apikey = config.sops.placeholder."porkbun-nano/api-key";
            domain = "nanoyaki.space";
            subdomain = "*";
          }
          {
            domain = "theless.one";
            subdomain = "at01";
          }
          # Remove this soon
          {
            domain = "theless.one";
            subdomain = "";
          }
          {
            domain = "theless.one";
            subdomain = "*";
          }
        ];
      };

      imports = [ inputs.self.nixosModules.oink ];
      self.oink.configFile = config.sops.templates."oink.json".path;
    };
}
