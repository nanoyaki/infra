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
            subdomain = "*";
            skipIPv6 = true;
          }
        ];
      };

      imports = [ inputs.self.nixosModules.oink ];
      self.oink.configFile = tpl."oink.json".path;
      systemd.services.oink.restartTriggers = [
        tpl."oink.json".file
        config.programs.dnscontrol.configFile
      ];

      programs.dnscontrol.credentials.porkbun-thelessone = {
        type = "porkbun";
        api_key = "PORKBUN_API_KEY_THELESSONE";
        secret_key = "PORKBUN_SECRET_API_KEY_THELESSONE";
      };

      programs.dnscontrol.domains."theless.one" = {
        provider = "porkbun-thelessone";
        registrar = "porkbun-thelessone";

        cname.at01.value = "@";
        cname.at02.value = "ao4s0dnu2d2vzzc6.myfritz.net.";
      };
    };
}
