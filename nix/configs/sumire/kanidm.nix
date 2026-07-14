{
  flake.nixosModules.sumire-kanidm =
    { pkgs, config, ... }:

    let
      inherit (config) sec;
      cfg = config.services.kanidm;
    in

    {
      sec."kanidm/admin-password".owner = cfg;

      services.caddy.virtualHosts."id.serdexmethylpheni.date" = {
        useACMEHost = "serdexmethylpheni.date";
        extraConfig = ''
          reverse_proxy [::1]:6767
        '';
      };

      services.kanidm = {
        enable = true;
        package = pkgs.kanidm_1_10.withSecretProvisioning;

        server.settings = {
          domain = "id.serdexmethylpheni.date";
          origin = "https://id.serdexmethylpheni.date";
          bindaddress = "[::1]:6767";
          http_client_address_info.x-forward-for = [
            "127.0.0.1"
            "::1"
          ];
        };

        provision = {
          enable = true;
          idmAdminPasswordFile = sec."kanidm/admin-password".path;

          persons.nanoyaki = {
            displayName = "Nanoyaki";
            mailAddresses = [ "contact@nanoyaki.space" ];
          };
        };
      };
    };
}
