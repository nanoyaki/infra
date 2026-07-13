{ inputs, ... }:

{
  flake.nixosModules.sentinel-tailscale =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib) filter;
      inherit (config) prt dmn sec;

      server = inputs.self.nixosConfigurations.thelessone.config;
    in

    {
      disabledModules = [ "services/networking/headplane.nix" ];
      imports = [ inputs.headplane.nixosModules.headplane ];

      sec = with config.services.headscale; {
        "headscale/oidc-secret".owner = user;
        "headplane/api-key".owner = user;
        "headplane/oidc-secret".owner = user;
        "headplane/cookie-secret".owner = user;
        tailscale = { };
      };

      prt.headscale = 8004;
      prt.headplane = 8005;

      dmn.headscale = "headscale.nanoyaki.space";
      dmn.headplane = "headplane.nanoyaki.space";

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "server";
        authKeyFile = sec.tailscale.path;
        extraUpFlags = [
          "--login-server"
          "https://${dmn.headscale}"
        ];
      };

      services.headscale = {
        enable = true;

        address = "127.0.0.1";
        port = prt.headscale;

        settings = {
          server_url = "https://${dmn.headscale}";

          policy.path = pkgs.writeText "acl.hujson" (
            builtins.toJSON {
              acls = [
                {
                  action = "accept";
                  src = [ "*" ];
                  dst = [
                    "thelessone:*"
                    "sentinel:*"
                  ];
                }
                {
                  action = "accept";
                  src = [ "contact@nanoyaki.space" ];
                  dst = [ "kanokoyuri:*" ];
                }
              ];

              hosts = {
                thelessone = "100.64.0.2";
                sentinel = "100.64.0.4";
                kanokoyuri = "100.64.0.11";
              };
            }
          );

          node.expiry = 0;
          oidc = {
            issuer = "https://${server.dmn.pocket-id}";
            client_id = "8d80ec56-c0d9-45ef-8ebb-7abd0c708e76";
            client_secret_path = sec."headscale/oidc-secret".path;
            pkce.enabled = true;
            pkce.method = "S256";

            scope = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
          };

          dns = {
            magic_dns = true;
            base_domain = dmn.self;

            override_local_dns = true;
            nameservers.global = [
              "1.1.1.1"
              "1.0.0.1"
            ];

            extra_records =
              (map (domain: {
                name = domain;
                type = "A";
                value = "100.64.0.2";
              }) (filter (lib.hasInfix dmn.self) (builtins.attrValues server.dmn)))
              ++ map (domain: {
                name = domain;
                type = "A";
                value = "100.64.0.4";
              }) (filter (lib.hasInfix dmn.self) (builtins.attrValues dmn));
          };
        };
      };

      services.headplane = {
        enable = true;

        settings = {
          server = {
            base_url = "https://${dmn.headplane}";
            port = prt.headplane;
            cookie_secret_path = sec."headplane/cookie-secret".path;
          };

          headscale = {
            url = "https://${dmn.headscale}";
            config_path = config.services.headscale.configFile;
            api_key_path = sec."headplane/api-key".path;
          };

          oidc = {
            issuer = "https://${server.dmn.pocket-id}";
            client_id = "e9368c4e-fa05-4cf8-83c8-04555cb3e1ce";
            client_secret_path = sec."headplane/oidc-secret".path;
            disable_api_key_login = true;
            use_pkce = true;
          };
        };
      };

      sentinel.caddy.host.${dmn.headscale}.proxy.port = prt.headscale;
      sentinel.caddy.host.${dmn.headplane} = {
        proxy.port = prt.headplane;
        config = ''
          redir / /admin
        '';
      };
    };
}
