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

      inherit (config) dmn plh tpl;

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
              @public not remote_ip 100.64.0.0/24 10.0.0.0/24 127.0.0.1/32 ::1/32

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
        networking.firewall.allowedTCPPorts = [ 443 ];

        sec = {
          "caddy-env-vars/nik" = { };
          "caddy-env-vars/hana" = { };
          "caddy-env-vars/shared" = { };
          "caddy-env-vars/thelessone" = { };
        };

        dmn.file-server = "na55l3zepb4kcg0zryqbdnay.theless.one";

        tpl."caddy-users.env".file = pkgs.writeEnv "caddy-users.env" {
          nik = "nik ${plh."caddy-env-vars/nik"}";
          hana = "hana ${plh."caddy-env-vars/hana"}";
          shared = "user ${plh."caddy-env-vars/shared"}";
          thelessone = "thelessone ${plh."caddy-env-vars/thelessone"}";
        };

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
          environmentFile = tpl."caddy-users.env".path;
          email = "contact@nanoyaki.space";

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
