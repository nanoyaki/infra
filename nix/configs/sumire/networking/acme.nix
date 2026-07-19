{
  flake.nixosModules.sumire-acme =
    { pkgs, config, ... }:

    let
      inherit (config) plh;
    in

    {
      sec = {
        "porkbun/api-key" = { };
        "porkbun/secret-api-key" = { };
      };

      tpl."porkbun.env".file = pkgs.writeEnv "porkbun.env.template" {
        PORKBUN_API_KEY = plh."porkbun/api-key";
        PORKBUN_SECRET_API_KEY = plh."porkbun/secret-api-key";
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
      };
    };
}
