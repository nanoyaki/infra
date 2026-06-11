{
  flake.nixosModules.thelessone-opencloud =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config)
        prt
        dmn
        plh
        tpl
        ;
    in

    {
      sec = {
        "opencloud/oidc-id" = { };
        "opencloud/jwt-secret" = { };
        "opencloud/service-account-id" = { };
        "opencloud/service-account-secret" = { };
      };

      tpl."opencloud.env".file = pkgs.writeEnv "opencloud.env.template" {
        OC_OIDC_CLIENT_ID = plh."opencloud/oidc-id";
        OC_JWT_SECRET = plh."opencloud/jwt-secret";
        OC_SERVICE_ACCOUNT_ID = plh."opencloud/service-account-id";
        OC_SERVICE_ACCOUNT_SECRET = plh."opencloud/service-account-secret";
      };

      prt.opencloud = 8025;
      dmn.opencloud = "cloud.theless.one";

      systemd.services.opencloud-init-config.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.opencloud.wantedBy = lib.mkForce [ "server-services.target" ];
      services.opencloud = {
        enable = true;
        url = "https://${dmn.opencloud}";
        port = prt.opencloud;

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
              "https://${dmn.opencloud}"
              "https://${dmn.pocket-id}"
            ];
            frame-src = [
              "https://${dmn.opencloud}"
              "https://${dmn.pocket-id}"
            ];
            script-src = [
              "https://${dmn.opencloud}"
              "https://${dmn.pocket-id}"
            ];
          };
        };

        environment = {
          OC_INSECURE = "false";
          PROXY_TLS = "false";
          OC_OIDC_ISSUER = "https://${dmn.pocket-id}";
          OC_EXCLUDE_RUN_SERVICES = "idp";
          WEB_OIDC_SCOPE = "openid profile email groups";
        };

        environmentFile = tpl."opencloud.env".path;
      };

      thelessone.caddy.vHost.${dmn.opencloud}.proxy.port = prt.opencloud;
    };
}
