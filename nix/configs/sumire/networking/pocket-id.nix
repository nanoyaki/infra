{
  flake.nixosModules.sumire-pocket-id =
    { lib, config, ... }:

    let
      inherit (lib) mkMerge mkIf;
      inherit (config) sec tpl;
    in

    mkMerge [
      {
        services.pocket-id.enable = true;
        services.pocket-id.settings = {
          APP_URL = "https://id.serdexmethylpheni.date";
          TRUST_PROXY = true;
          ANALYTICS_DISABLED = true;
          PORT = 6767;
        };
      }
      # In case we ever decide to turn off OIDC
      (mkIf config.services.pocket-id.enable {
        sec."pocket-id/encryption".owner = "pocket-id";

        services.pocket-id.credentials.ENCRYPTION_KEY = sec."pocket-id/encryption".path;

        programs.dnscontrol.domains."serdexmethylpheni.date".cname.id.value = "@";

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

        services.matrix-continuwuity.settings.global.oauth.oidc = {
          discovery_url = "https://id.serdexmethylpheni.date";
          client_id = "9a4974c7-dce6-498e-aca3-59ee7535d24f";
          client_secret_file = sec."continuwuity/oidc-secret".path;

          # Claims
          additional_scopes = [
            "openid"
            "profile"
            "email"
          ];
          email_claim = "email";
          profile_key_map = {
            avatar_url = "picture";
            display_name = "preferred_username";
          };
          profile_key_import_mode = "on_registration";
        };
      })
    ];
}
