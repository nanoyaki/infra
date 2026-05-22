{
  flake.nixosModules.sentinel-caddy =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib)
        types
        mkOption
        mapAttrs
        optionalString
        replaceStrings
        ;

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
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        services.caddy = {
          enable = true;
          email = "contact@nanoyaki.space";

          globalConfig = ''
            auto_https disable_certs
          '';

          extraConfig = ''
            (errors) {
              handle_errors {
                root * ${pkgs.theless-dot-one}
                try_files /{http.error.status_code}.html /index.html
                file_server
              }
            }
          '';

          virtualHosts = mapAttrs (_: domainCfg: {
            listenAddresses = [
              "127.0.0.1"
              "::1"
              "100.64.0.4"
            ]
            ++ lib.optional (!domainCfg.useTailnet) "0.0.0.0";

            extraConfig = ''
              ${optionalString (
                domainCfg.tls.cert != null && domainCfg.tls.key != null
              ) "tls ${domainCfg.tls.cert} ${domainCfg.tls.key}"}

              ${domainCfg.config}

              ${optionalString (
                domainCfg.proxy.port != null
              ) "reverse_proxy ${domainCfg.proxy.host}:${toString domainCfg.proxy.port}"}
            '';
          }) cfg.host;
        };

        sentinel.tailscale.services = lib.foldl (
          acc: domain:

          let
            finalDomain = builtins.elemAt (lib.splitString "." (
              replaceStrings [ "http://" "https://" ] [ "" "" ] domain
            )) 0;
          in

          acc
          // lib.optionalAttrs cfg.host.${domain}.useTailnet {
            ${finalDomain} = "100.64.0.4";
          }
        ) { } (builtins.attrNames cfg.host);
      };
    };
}
