{
  flake.nixosModules.thelessone-acme =
    {
      pkgs,
      config,
      ...
    }:

    let
      inherit (config) dmn plh tpl;
    in

    {
      sec = {
        "porkbun/api-key" = { };
        "porkbun/secret-api-key" = { };
        "porkbun-nano/api-key" = { };
        "porkbun-nano/secret-api-key" = { };
        "porkbun-ashley/api-key" = { };
        "porkbun-ashley/secret-api-key" = { };
      };

      tpl."theless.one-acme.env".file = pkgs.writeEnv "theless.one-acme.env.template" {
        PORKBUN_API_KEY = plh."porkbun/api-key";
        PORKBUN_SECRET_API_KEY = plh."porkbun/secret-api-key";
      };

      tpl."nanoyaki.space-acme.env".file = pkgs.writeEnv "nanoyaki.space-acme.env.template" {
        PORKBUN_API_KEY = plh."porkbun-nano/api-key";
        PORKBUN_SECRET_API_KEY = plh."porkbun-nano/secret-api-key";
      };

      tpl."aslija.com-acme.env".file = pkgs.writeEnv "aslija.com-acme.env.template" {
        PORKBUN_API_KEY = plh."porkbun-ashley/api-key";
        PORKBUN_SECRET_API_KEY = plh."porkbun-ashley/secret-api-key";
      };

      security.acme = {
        acceptTerms = true;
        defaults = {
          inherit (config.services.caddy) group;
          email = "contact@${dmn.nanoyaki-space}";

          dnsProvider = "porkbun";
          dnsResolver = "173.245.58.37:53";
          dnsPropagationCheck = true;
        };

        certs.${dmn.self} = {
          environmentFile = tpl."theless.one-acme.env".path;
          extraDomainNames = [ "*.${dmn.self}" ];
        };

        certs.${dmn.nanoyaki-space} = {
          environmentFile = tpl."nanoyaki.space-acme.env".path;
          extraDomainNames = [ "*.${dmn.nanoyaki-space}" ];
        };

        certs.${dmn.aslija-com} = {
          environmentFile = tpl."aslija.com-acme.env".path;
          extraDomainNames = [ "*.${dmn.aslija-com}" ];
        };
      };
    };
}
