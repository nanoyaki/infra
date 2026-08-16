{
  flake.nixosModules.tubaki-acme =
    { pkgs, config, ... }:

    let
      inherit (config) plh tpl;
    in

    {
      sec = {
        "porkbun/api-key" = { };
        "porkbun/secret-api-key" = { };
        "porkbun-thelessone/api-key" = { };
        "porkbun-thelessone/secret-api-key" = { };
        "porkbun-aslija/api-key" = { };
        "porkbun-aslija/secret-api-key" = { };
      };

      tpl."porkbun.env".file = pkgs.writeEnv "porkbun.env.template" {
        PORKBUN_API_KEY = plh."porkbun/api-key";
        PORKBUN_SECRET_API_KEY = plh."porkbun/secret-api-key";
      };

      tpl."porkbun-thelessone.env".file = pkgs.writeEnv "porkbun-thelessone.env.template" {
        PORKBUN_API_KEY = plh."porkbun-thelessone/api-key";
        PORKBUN_SECRET_API_KEY = plh."porkbun-thelessone/secret-api-key";
      };

      tpl."porkbun-aslija.env".file = pkgs.writeEnv "porkbun-aslija.env.template" {
        PORKBUN_API_KEY = plh."porkbun-aslija/api-key";
        PORKBUN_SECRET_API_KEY = plh."porkbun-aslija/secret-api-key";
      };

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "contact@nanoyaki.space";
          group = "caddy";

          dnsProvider = "porkbun";
          dnsResolver = "173.245.58.37:53";
          dnsPropagationCheck = true;
        };

        certs."nanoyaki.space" = {
          extraDomainNames = [
            "*.nanoyaki.space"
            "hanakretzer.de"
            "*.hanakretzer.de"
          ];
          environmentFile = tpl."porkbun.env".path;
        };

        certs."theless.one" = {
          extraDomainNames = [ "*.theless.one" ];
          environmentFile = tpl."porkbun-thelessone.env".path;
        };

        certs."aslija.com" = {
          extraDomainNames = [ "*.aslija.com" ];
          environmentFile = tpl."porkbun-aslija.env".path;
        };
      };
    };
}
