{ inputs, ... }:

{
  flake.nixosModules.thelessone-ddns =
    { config, ... }:

    {
      sops.templates."oink.json".content = builtins.toJSON {
        global = {
          secretapikey = config.sops.placeholder."porkbun/secret-api-key";
          apikey = config.sops.placeholder."porkbun/api-key";
          interval = 900;
          ttl = 600;
          skipIPv6 = true;
        };

        domains = [
          {
            domain = "theless.one";
            subdomain = "";
            skipIPv6 = true;
          }
          {
            domain = "theless.one";
            subdomain = "at01";
            skipIPv6 = true;
          }
          {
            domain = "theless.one";
            subdomain = "*";
            skipIPv6 = true;
          }
          {
            secretapikey = config.sops.placeholder."porkbun-ashley/secret-api-key";
            apikey = config.sops.placeholder."porkbun-ashley/api-key";
            domain = "aslija.com";
            subdomain = "";
            skipIPv6 = true;
          }
          {
            secretapikey = config.sops.placeholder."porkbun-ashley/secret-api-key";
            apikey = config.sops.placeholder."porkbun-ashley/api-key";
            domain = "aslija.com";
            subdomain = "*";
            skipIPv6 = true;
          }
        ];
      };

      imports = [ inputs.self.nixosModules.oink ];
      self.oink.configFile = config.sops.templates."oink.json".path;
      systemd.services.oink.restartTriggers = [ config.sops.templates."oink.json".file ];
    };
}
