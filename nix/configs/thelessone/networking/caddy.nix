{
  flake.nixosModules.thelessone-caddy =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        types
        mkOption
        mkEnableOption
        mapAttrs
        optionalString
        mkIf
        hasInfix
        filterAttrs
        hasPrefix
        ;

      inherit (config)
        dmn
        prt
        ;

      cfg = config.thelessone.caddy;

      vHostModule =
        { name, ... }:

        {
          freeformType = types.attrsOf types.anything;

          options = {
            enable = (mkEnableOption "virtual host ${name}") // {
              default = true;
            };

            proxy = {
              port = mkOption {
                type = types.nullOr types.port;
                default = null;
              };

              host = mkOption {
                type = types.str;
                default = "localhost";
              };
            };

            extraConfig = mkOption {
              type = types.str;
              default = "";
            };

            useTailnet = mkEnableOption "tailnet virtual host";
          };
        };

      mapVhosts = mapAttrs (
        domain: vHost:
        {
          extraConfig =
            optionalString vHost.useTailnet ''
              @public not remote_ip 100.64.0.0/24 fd7a:115c:a1e0::/48 10.0.0.0/24 fd1e:5501:7e00::/64 127.0.0.1/32 ::1/32

              handle @public {
                error 404
              }
            ''
            + ''
              ${vHost.extraConfig}
            ''
            + optionalString (vHost.proxy.port != null) ''
              reverse_proxy ${vHost.proxy.host}:${toString vHost.proxy.port}
            ''
            + ''
              import error_handling
            '';
          useACMEHost = mkIf (hasInfix dmn.self domain && !(hasPrefix "http://" domain)) dmn.self;
          listenAddresses = [
            "0.0.0.0"
            "::"
          ];
        }
        // (removeAttrs vHost [
          "enable"
          "proxy"
          "extraConfig"
          "useTailnet"
          "localOnly"
        ])
      );

      enabledHosts = filterAttrs (_: hostCfg: hostCfg.enable) cfg.vHost;
    in

    # TODO: Add OAuth, OIDP, or LDAP
    {
      options.thelessone.caddy.vHost = mkOption {
        type = types.attrsOf (types.submodule vHostModule);
        default = { };
      };

      config = {
        networking.firewall.allowedTCPPorts = [ prt.https ];

        dmn.file-server = "na55l3zepb4kcg0zryqbdnay.theless.one";

        networking.extraHosts = lib.concatStringsSep "\n" (
          map (
            domain:
            "127.0.0.1 ${
              builtins.head (lib.splitString "/" (lib.replaceStrings [ "http://" "https://" ] [ "" "" ] domain))
            }"
          ) (builtins.attrNames enabledHosts)
        );

        thelessone.caddy.vHost."http://${dmn.file-server}".extraConfig = ''
          root * /var/www/theless.one
          file_server * browse
        '';

        systemd.services.caddy.wantedBy = lib.mkForce [ "server-services.target" ];
        services.caddy = {
          enable = true;
          enableReload = true;
          email = "contact@nanoyaki.space";
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/greenpau/caddy-security@v1.1.62" ];
            hash = "sha256-68hfE8KvaJ+nU5JTAhbUGYjbgiLsyF9iijLk80xfjGc=";
          };

          logFormat = lib.mkForce ''
            format console
            level INFO
          '';

          globalConfig = ''
            auto_https disable_certs
          '';

          virtualHosts = mapVhosts enabledHosts;
        };

        systemd.services.caddy = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
        };
      };
    };
}
