{
  flake.nixosModules.sentinel-caddy =
    {
      lib,
      config,
      ...
    }:

    let
      inherit (lib)
        types
        mkOption
        mapAttrs
        optionalString
        ;

      inherit (config) prt;

      cfg = config.sentinel.caddy;
    in

    {
      options.sentinel.caddy.host = mkOption {
        type = types.attrsOf (
          types.submodule (
            { name, ... }:

            let
              baseDomain = lib.concatStringsSep "." (lib.takeEnd 2 (lib.splitString "." name));
            in

            {
              options = {
                config = mkOption {
                  type = types.str;
                  default = "";
                };

                proxy.port = mkOption {
                  type = types.nullOr types.port;
                  default = null;
                };

                proxy.host = mkOption {
                  type = types.str;
                  default = "127.0.0.1";
                };

                tls.cert = mkOption {
                  type = types.nullOr types.externalPath;
                  default = config.sentinel.certs.${lib.replaceString "." "-" baseDomain}.cert or null;
                };

                tls.key = mkOption {
                  type = types.nullOr types.externalPath;
                  default = config.sentinel.certs.${lib.replaceString "." "-" baseDomain}.key or null;
                };

                useTailnet = mkOption {
                  type = types.bool;
                  default = false;
                };

                internal = mkOption {
                  type = types.bool;
                  default = false;
                };
              };
            }
          )
        );
        default = { };
      };

      config = {
        networking.firewall.allowedTCPPorts = with prt; [
          http
          https
        ];

        services.caddy = {
          enable = true;
          enableReload = true;
          email = "contact@nanoyaki.space";

          globalConfig = ''
            auto_https disable_certs
          '';

          logFormat = ''
            format console
          '';

          extraConfig = ''
            (errors) {
              handle_errors {
                respond "{err.status_code} - {err.message}"
              }
            }
          '';

          virtualHosts = mapAttrs (_: domainCfg: {
            listenAddresses = [
              "0.0.0.0"
              "::"
            ];

            extraConfig =
              optionalString (domainCfg.tls.cert != null && domainCfg.tls.key != null) ''
                tls ${domainCfg.tls.cert} ${domainCfg.tls.key}
              ''
              + optionalString domainCfg.useTailnet ''
                @public not remote_ip 100.64.0.0/24 10.0.0.0/24 127.0.0.1/32 ::1/32

                handle @public {
                  error 404
                }
              ''
              + ''
                ${domainCfg.config}

                import errors
              ''
              + optionalString (domainCfg.proxy.port != null) ''
                reverse_proxy ${domainCfg.proxy.host}:${toString domainCfg.proxy.port}
              '';
          }) cfg.host;
        };
      };
    };
}
