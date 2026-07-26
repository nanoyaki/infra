{
  flake.nixosModules.sentinel-acme =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib)
        types
        mkOption
        mapAttrs'
        ;

      inherit (config) dmn;
    in

    {
      options.sentinel.certs = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              cert = mkOption {
                type = types.path;
              };

              key = mkOption {
                type = types.path;
              };
            };
          }
        );
        default = { };
      };

      config = {
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

        sentinel.certs = mapAttrs' (
          name: _:

          let
            dashName = lib.replaceStrings [ "." ] [ "-" ] name;
          in

          {
            name = dashName;
            value = {
              cert = "/var/lib/acme/${name}/cert.pem";
              key = "/var/lib/acme/${name}/key.pem";
            };
          }
        ) config.security.acme.certs;

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
            environmentFile = config.sops.templates."nanoyaki.space-acme.env".path;
            extraDomainNames = [ "*.nanoyaki.space" ];
            reloadServices = [ "caddy.service" ];
          };

          certs.${dmn.self} = {
            environmentFile = config.sops.templates."theless.one-acme.env".path;
            extraDomainNames = [ "*.${dmn.self}" ];
            reloadServices = [ "caddy.service" ];
          };
        };
      };
    };
}
