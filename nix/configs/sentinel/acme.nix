{
  flake.nixosModules.sentinel-acme =
    {
      pkgs,
      config,
      ...
    }:

    {
      sops = {
        secrets.id_acme_thelessone = { };

        templates."theless.one-acme.env".file = pkgs.writeEnv "theless.one-acme.env.template" {
          PORKBUN_API_KEY = config.sops.placeholder."porkbun/api-key";
          PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun/secret-api-key";
        };

        templates."nanoyaki.space-acme.env".file = pkgs.writeEnv "nanoyaki.space-acme.env.template" {
          PORKBUN_API_KEY = config.sops.placeholder."porkbun/pds-api-key";
          PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun/pds-secret-api-key";
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

        certs."nanoyaki.space" = {
          inherit (config.services.traefik) group;
          environmentFile = config.sops.templates."nanoyaki.space-acme.env".path;
          extraDomainNames = [ "*.nanoyaki.space" ];
          reloadServices = [ "traefik.service" ];
        };

        certs."theless.one" = {
          inherit (config.services.traefik) group;
          environmentFile = config.sops.templates."theless.one-acme.env".path;
          extraDomainNames = [ "*.theless.one" ];
          reloadServices = [ "traefik.service" ];
        };
      };
    };
}
