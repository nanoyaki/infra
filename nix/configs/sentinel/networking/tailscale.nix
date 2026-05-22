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
      inherit (lib)
        mkOption
        types
        ;

      cfg = config.sentinel.tailscale;
    in

    {
      disabledModules = [ "services/networking/headplane.nix" ];
      imports = [ inputs.headplane.nixosModules.headplane ];

      options.sentinel.tailscale.services = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = lib.literalExpression ''{ "<service>" = "100.64.0.1"; }'';
      };

      config = {
        sops.secrets = with config.services.headscale; {
          "headscale/oidc-secret".owner = user;
          "headplane/api-key".owner = user;
          "headplane/oidc-secret".owner = user;
          "headplane/cookie-secret".owner = user;
          tailscale = { };
        };

        services.tailscale = {
          enable = true;
          useRoutingFeatures = "server";
          authKeyFile = config.sops.secrets.tailscale.path;
          extraUpFlags = [
            "--login-server"
            "https://headscale.nanoyaki.space"
          ];
        };

        services.headplane = {
          enable = true;

          settings = {
            server = {
              base_url = "https://headplane.nanoyaki.space";
              port = 8009;
              cookie_secret_path = config.sops.secrets."headplane/cookie-secret".path;
            };

            headscale = {
              url = "https://headscale.nanoyaki.space";
              config_path = config.services.headscale.configFile;
              api_key_path = config.sops.secrets."headplane/api-key".path;
            };

            oidc = {
              issuer = "https://id.theless.one";
              client_id = "e9368c4e-fa05-4cf8-83c8-04555cb3e1ce";
              client_secret_path = config.sops.secrets."headplane/oidc-secret".path;
              disable_api_key_login = true;
              use_pkce = true;
            };
          };
        };

        services.headscale = {
          enable = true;

          address = "127.0.0.1";
          port = 8008;

          settings = {
            server_url = "https://headscale.nanoyaki.space";

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
                ];

                hosts.thelessone = "100.64.0.2";
                hosts.sentinel = "100.64.0.4";
              }
            );

            oidc = {
              issuer = "https://id.theless.one";
              client_id = "8d80ec56-c0d9-45ef-8ebb-7abd0c708e76";
              client_secret_path = config.sops.secrets."headscale/oidc-secret".path;
              pkce.enabled = true;
              pkce.method = "S256";

              scope = [
                "openid"
                "profile"
                "email"
                "groups"
              ];
              expiry = 0;
            };

            dns =
              let
                filterThelessone = lib.filterAttrs (domain: _: lib.hasInfix "theless.one" domain);

                mkServiceName =
                  domain:
                  builtins.head (
                    builtins.split ".theless.one" (lib.replaceStrings [ "http://" "https://" ] [ "" "" ] domain)
                  );

                privateRecords =
                  map
                    (domain: {
                      name = "${mkServiceName domain}.theless.one";
                      type = "A";
                      value = "100.64.0.2";
                    })
                    (
                      builtins.attrNames (
                        filterThelessone inputs.self.nixosConfigurations.thelessone.config.thelessone.caddy.vHost
                      )
                    )
                  ++ map (domain: {
                    name = "${mkServiceName domain}.theless.one";
                    type = "A";
                    value = "100.64.0.4";
                  }) (builtins.attrNames (filterThelessone config.sentinel.caddy.host));
              in
              {
                base_domain = "theless.one";
                override_local_dns = true;
                nameservers.global = [
                  "1.1.1.1"
                  "1.0.0.1"
                  "8.8.8.8"
                  "8.8.4.4"
                ];
                extra_records =
                  privateRecords
                  ++ (map (name: {
                    name = "${name}.theless.one";
                    type = "A";
                    value = cfg.services.${name};
                  }) (builtins.attrNames cfg.services));
              };
          };
        };

        sentinel.caddy.host."headscale.nanoyaki.space".proxy = {
          inherit (config.services.headscale) port;
        };

        sentinel.caddy.host."headplane.nanoyaki.space" = {
          config = ''
            redir / /admin
          '';

          proxy = {
            inherit (config.services.headplane.settings.server) port;
          };
        };
      };
    };
}
