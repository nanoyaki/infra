{
  flake.nixosModules.sumire-continuwuity =
    { config, ... }:

    let
      inherit (config) sec prt;

      cfg = config.services.matrix-continuwuity;
    in

    {
      prt.continuwuity = 6167;

      users.users.${config.services.caddy.user}.extraGroups = [ cfg.group ];

      sec."continuwuity/registration" = {
        inherit (cfg) group;
        owner = cfg.user;
        mode = "400";
      };

      sec."continuwuity/oidc-secret" = {
        group = "continuwuity-oidc";
        owner = cfg.user;
        mode = "440";
      };

      users.groups.continuwuity-oidc = { };

      services.matrix-continuwuity = {
        enable = true;

        settings = {
          global = {
            port = [ prt.continuwuity ];
            server_name = "serdexmethylpheni.date";
            max_request_size = 1024 * 1024 * 50;
            unix_socket_path = "/run/continuwuity.sock";
            unix_socket_perms = 660;

            database_backups_to_keep = 3;
            # 4 - IPv6 then IPv4
            ip_lookup_strategy = 4;
            # Caddy's default "real ip" header
            request_ip_source = "x_forwarded_for";
            registration_token_file = sec."continuwuity/registration".path;

            oauth.oidc = {
              discovery_url = "https://id.serdexmethylpheni.date/oauth2/oidc/continuwuity";
              client_id = "continuwuity";
              client_secret_file = sec."continuwuity/oidc-secret".path;

              # Claims
              email_claim = "email";
              profile_key_map = {
                avatar_url = "picture";
                display_name = "preferred_username";
              };
              profile_key_import_mode = "on_login";
            };

            url_preview_check_root_domain = true;
            url_preview_domain_explicit_allowlist = [
              "google.com"
              "duckduckgo.com"

              # Own domains
              "nanoyaki.space"
              "theless.one"
              "hanakretzer.de"
              "aslija.com"
            ];

            url_preview_max_spider_size = 1024 * 1024 * 10;
            url_preview_allow_audio_video = true;

            well_known = {
              client = "https://serdexmethylpheni.date";
              server = "serdexmethylpheni.date:443";
            };
          };

        };
      };

      users.users.${config.services.kanidm.user}.extraGroups = [ "continuwuity-oidc" ];
      services.kanidm.provision.systems.oauth2.continuwuity = {
        originLanding = "https://serdexmethylpheni.date";
        originUrl = "https://serdexmethylpheni.date/_continuwuity/oidc/complete";
        basicSecretFile = sec."continuwuity/oidc-secret".path;
        preferShortUsername = true;
        scopeMaps.idm_all_persons = [
          "openid"
          "email"
          "profile"
        ];
      };
    };
}
