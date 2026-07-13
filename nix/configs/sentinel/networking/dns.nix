{
  flake.nixosModules.sentinel-ddns =
    { config, ... }:

    let
      inherit (config) plh;
    in

    {
      dmn.nanoyaki-space = "nanoyaki.space";

      sec = {
        "porkbun/secret-api-key" = { };
        "porkbun/api-key" = { };
        "porkbun/pds-secret-api-key" = { };
        "porkbun/pds-api-key" = { };
      };

      tpl."creds.json".content = builtins.toJSON {
        porkbun = {
          TYPE = "PORKBUN";
          api_key = plh."porkbun/api-key";
          secret_key = plh."porkbun/secret-api-key";
        };
      };

      programs.dnscontrol.credentials = {
        porkbun = {
          type = "porkbun";
          api_key = "PORKBUN_API_KEY";
          secret_key = "PORKBUN_SECRET_API_KEY";
        };

        porkbun-thelessone = {
          type = "porkbun";
          api_key = "PORKBUN_API_KEY_THELESSONE";
          secret_key = "PORKBUN_SECRET_API_KEY_THELESSONE";
        };

        porkbun-aslija = {
          type = "porkbun";
          api_key = "PORKBUN_API_KEY_ASLIJA";
          secret_key = "PORKBUN_SECRET_API_KEY_ASLIJA";
        };
      };

      programs.dnscontrol.domains."theless.one" = {
        provider = "porkbun-thelessone";
        registrar = "porkbun-thelessone";

        cname.de01.value = "nanoyaki.space.";
      };

      programs.dnscontrol.domains."nanoyaki.space" = {
        provider = "porkbun";
        registrar = "porkbun";

        a."@".address = "85.215.152.236";
        a."*".address = "85.215.152.236";
        aaaa."@".address = "2a01:239:454:9300::1";
        aaaa."*".address = "2a01:239:454:9300::1";
        cname.de01.value = "@";
        cname.pds.value = "@";

        txt = [
          {
            subdomain = "_atproto";
            value = "did=did:plc:majihettvb7ieflgmkvujecu";
            ttl = 86400;
          }
          {
            subdomain = "_discord";
            value = "dh=a90a54350f3a09336054e2f344a92c1bf81eb801";
            ttl = 86400;
          }
        ];
      };
    };
}
