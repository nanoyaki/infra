{ inputs, ... }:

{
  flake.nixosModules.thelessone-ddns =
    { config, ... }:

    let
      inherit (config) plh tpl;
    in

    {
      tpl."oink.json".content = builtins.toJSON {
        global = {
          secretapikey = plh."porkbun/secret-api-key";
          apikey = plh."porkbun/api-key";
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
            secretapikey = plh."porkbun-ashley/secret-api-key";
            apikey = plh."porkbun-ashley/api-key";
            domain = "aslija.com";
            subdomain = "";
            skipIPv6 = true;
          }
          {
            secretapikey = plh."porkbun-ashley/secret-api-key";
            apikey = plh."porkbun-ashley/api-key";
            domain = "aslija.com";
            subdomain = "*";
            skipIPv6 = true;
          }
        ];
      };

      imports = [ inputs.self.nixosModules.oink ];
      self.oink.configFile = tpl."oink.json".path;
      systemd.services.oink.restartTriggers = [ tpl."oink.json".file ];
    };
}
