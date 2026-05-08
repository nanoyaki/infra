{
  flake.nixosModules.thelessone-opencloud =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      plh = config.sops.placeholder;
      tpl = config.sops.templates;

      cfg = config.services.opencloud;
    in

    {
      sops.secrets = {
        "opencloud/oidc-id" = { };
        "opencloud/jwt-secret" = { };
      };

      sops.templates."opencloud.env".file = pkgs.writeEnv "opencloud.env.template" {
        OC_OIDC_CLIENT_ID = plh."opencloud/oidc-id";
        OC_JWT_SECRET = plh."opencloud/jwt-secret";
      };

      systemd.services.opencloud-init-config.wantedBy = lib.mkForce [ "server-services.nix" ];
      systemd.services.opencloud.wantedBy = lib.mkForce [ "server-services.nix" ];
      services.opencloud = {
        enable = true;
        url = "https://cloud.theless.one";

        settings = {
          api = {
            graph_assign_default_user_role = false;
            graph_username_match = "none";
          };

          proxy = {
            oidc.rewrite_well_known = true;
            auto_provision_accounts = true;
            user_oidc_claim = "preferred_username";
            user_cs3_claim = "username";
            role_assignment = {
              driver = "oidc";
              oidc_role_mapper = {
                role_claim = "groups";
                role_mapping = [
                  {
                    role_name = "admin";
                    claim_value = "opencloud_admin";
                  }
                  {
                    role_name = "spaceadmin";
                    claim_value = "opencloud_space_admin";
                  }
                  {
                    role_name = "user";
                    claim_value = "opencloud_user";
                  }
                  {
                    role_name = "guest";
                    claim_value = "opencloud_guest";
                  }
                ];
              };
            };
            csp_config_file_location = "/etc/opencloud/csp.yaml";
          };

          csp.directives = {
            connect-src = [
              "https://cloud.theless.one"
              "https://id.theless.one"
            ];
            frame-src = [
              "https://cloud.theless.one"
              "https://id.theless.one"
            ];
            script-src = [
              "https://cloud.theless.one"
              "https://id.theless.one"
            ];
          };
        };

        environment = {
          OC_INSECURE = "false";
          PROXY_TLS = "false";
          OC_OIDC_ISSUER = "https://id.theless.one";
          OC_EXCLUDE_RUN_SERVICES = "idp";
          WEB_OIDC_SCOPE = "openid profile email groups";
        };

        environmentFile = tpl."opencloud.env".path;
      };

      services.newt.blueprint.public-resources.opencloud = {
        name = "Opencloud";
        protocol = "http";
        full-domain = "cloud.theless.one";
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            inherit (cfg) port;
            method = "http";
          }
        ];
      };
    };
}
