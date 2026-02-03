{
  flake.nixosModules.thelessone-acme =
    {
      pkgs,
      config,
      ...
    }:

    {
      sops = {
        secrets = {
          "porkbun/api-key" = { };
          "porkbun/secret-api-key" = { };
          "porkbun-nano/api-key" = { };
          "porkbun-nano/secret-api-key" = { };
          "porkbun-ashley/api-key" = { };
          "porkbun-ashley/secret-api-key" = { };
        };

        templates."theless.one-acme.env".file = pkgs.writeEnv "theless.one-acme.env.template" {
          PORKBUN_API_KEY = config.sops.placeholder."porkbun/api-key";
          PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun/secret-api-key";
        };

        templates."nanoyaki.space-acme.env".file = pkgs.writeEnv "nanoyaki.space-acme.env.template" {
          PORKBUN_API_KEY = config.sops.placeholder."porkbun-nano/api-key";
          PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun-nano/secret-api-key";
        };

        templates."aslija.com-acme.env".file = pkgs.writeEnv "aslija.com-acme.env.template" {
          PORKBUN_API_KEY = config.sops.placeholder."porkbun-ashley/api-key";
          PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun-ashley/secret-api-key";
        };
      };

      security.acme = {
        acceptTerms = true;
        defaults = {
          inherit (config.services.caddy) group;
          email = "contact@nanoyaki.space";

          dnsProvider = "porkbun";
          dnsResolver = "173.245.58.37:53";
          dnsPropagationCheck = true;
        };

        certs."theless.one" = {
          environmentFile = config.sops.templates."theless.one-acme.env".path;
          extraDomainNames = [ "*.theless.one" ];
        };

        certs."nanoyaki.space" = {
          environmentFile = config.sops.templates."nanoyaki.space-acme.env".path;
          extraDomainNames = [ "*.nanoyaki.space" ];
        };

        certs."aslija.com" = {
          environmentFile = config.sops.templates."aslija.com-acme.env".path;
          extraDomainNames = [ "*.aslija.com" ];
        };
      };
    };
}
