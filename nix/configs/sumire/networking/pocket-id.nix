{
  flake.nixosModules.sumire-pocket-id =
    { config, ... }:

    let
      inherit (config) sec tpl;
    in

    {
      sec."pocket-id/encryption".owner = "pocket-id";

      services.pocket-id.enable = true;
      services.pocket-id.settings = {
        APP_URL = "https://id.serdexmethylpheni.date";
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
        PORT = 6767;
        ENCRYPTION_KEY_FILE = sec."pocket-id/encryption".path;
      };

      security.acme.certs."id.serdexmethylpheni.date" = {
        environmentFile = tpl."porkbun.env".path;
        reloadServices = [ "caddy.service" ];
      };

      services.caddy.virtualHosts."id.serdexmethylpheni.date" = {
        useACMEHost = "id.serdexmethylpheni.date";
        extraConfig = ''
          reverse_proxy 127.0.0.1:6767
        '';
      };
    };
}
