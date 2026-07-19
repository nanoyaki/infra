{
  flake.nixosModules.sumire-kanidm =
    { pkgs, config, ... }:

    let
      inherit (config) sec tpl;

      cfg = config.services.kanidm;
      cert = config.security.acme.certs."id.serdexmethylpheni.date";
    in

    {
      sec."kanidm/admin-password".owner = "kanidm";
      sec."kanidm/idm-admin-password".owner = "kanidm";

      security.acme.certs."id.serdexmethylpheni.date" = {
        group = "kanidm-cert";
        environmentFile = tpl."porkbun.env".path;
        reloadServices = [
          "caddy.service"
          "kanidm.service"
        ];
      };

      services.caddy.virtualHosts."id.serdexmethylpheni.date" = {
        useACMEHost = "id.serdexmethylpheni.date";
        extraConfig = ''
          reverse_proxy https://${cfg.server.settings.bindaddress} {
            transport http {
              tls_server_name ${cfg.server.settings.domain}
            }
          }
        '';
      };

      users.groups.kanidm-cert = { };
      users.users.${config.services.caddy.user}.extraGroups = [ "kanidm-cert" ];
      users.users.kanidm.extraGroups = [ "kanidm-cert" ];

      services.kanidm = {
        package = pkgs.kanidm_1_10.withSecretProvisioning;

        client.enable = true;
        client.settings.uri = cfg.server.settings.origin;

        server.enable = true;
        server.settings = {
          domain = "id.serdexmethylpheni.date";
          origin = "https://id.serdexmethylpheni.date";
          bindaddress = "[::1]:6767";
          ldapbindaddress = null;
          http_client_address_info.x-forward-for = [
            "127.0.0.1"
            "::1"
          ];

          tls_chain = "${cert.directory}/fullchain.pem";
          tls_key = "${cert.directory}/key.pem";
        };

        provision = {
          enable = true;
          autoRemove = true;
          acceptInvalidCerts = true;
          instanceUrl = "https://[::1]:6767";

          adminPasswordFile = sec."kanidm/admin-password".path;
          idmAdminPasswordFile = sec."kanidm/idm-admin-password".path;
          persons.nanoyaki = {
            displayName = "Nanoyaki";
            mailAddresses = [ "contact@nanoyaki.space" ];
          };

          groups.user.members = builtins.attrNames cfg.provision.persons;
        };
      };
    };
}
