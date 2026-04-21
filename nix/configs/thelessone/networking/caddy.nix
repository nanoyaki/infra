{ withSystem, ... }:

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
        mapAttrs'
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
                type = types.port;
                default = 0;
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

            localOnly = (mkEnableOption "bind to local host only") // {
              default = true;
            };

            pangolin = {
              name = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          };
        };

      mapVhosts = mapAttrs (
        domain: vHost:
        {
          extraConfig = ''
            ${vHost.extraConfig}

            ${optionalString (
              vHost.proxy.port != 0
            ) "reverse_proxy ${vHost.proxy.host}:${toString vHost.proxy.port}"}

            import error_handling
          '';
          useACMEHost = mkIf (hasInfix "theless.one" domain && !(hasPrefix "http://" domain)) "theless.one";
          listenAddresses = mkIf vHost.localOnly [
            "127.0.0.1"
            "[::1]"
          ];
        }
        // (removeAttrs vHost [
          "enable"
          "proxy"
          "extraConfig"
          "localOnly"
          "pangolin"
        ])
      );

      pangolinHosts = filterAttrs (_: vHost: vHost.pangolin.name != null);

      mapPangolinHosts =
        attrset:

        mapAttrs' (domain: vHost: {
          name = lib.replaceString " " "-" (lib.toLower vHost.pangolin.name);
          value = {
            inherit (vHost.pangolin) name;
            mode = "host";
            destination = "127.0.0.1";
            site = "utilized-olympic-marmot";
            alias = lib.removePrefix "http://" domain;
            tcp-ports = "80,443";
            udp-ports = "";
            disable-icmp = false;
            roles = [ "Member" ];
          };
        }) (pangolinHosts attrset);

      enabledHosts = filterAttrs (_: hostCfg: hostCfg.enable) cfg.vHost;

      # String -> String
      mkFileServer = directory: ''
        root * ${directory}
        file_server * browse
      '';
    in

    # TODO: Add OAuth, OIDP, or LDAP
    {
      options.thelessone.caddy.vHost = mkOption {
        type = types.attrsOf (types.submodule vHostModule);
        default = { };
      };

      config = {
        networking.firewall.allowedTCPPorts = [ 443 ];
        networking.firewall.interfaces.wg0.allowedTCPPorts = [
          80
          443
        ];

        sops.secrets = {
          "caddy-env-vars/nik" = { };
          "caddy-env-vars/hana" = { };
          "caddy-env-vars/shared" = { };
          "caddy-env-vars/thelessone" = { };
        };

        sops.templates."caddy-users.env".file = pkgs.writeEnv "caddy-users.env" {
          nik = "nik ${config.sops.placeholder."caddy-env-vars/nik"}";
          hana = "hana ${config.sops.placeholder."caddy-env-vars/hana"}";
          shared = "user ${config.sops.placeholder."caddy-env-vars/shared"}";
          thelessone = "thelessone ${config.sops.placeholder."caddy-env-vars/thelessone"}";
        };

        services.newt.blueprint.private-resources = mapPangolinHosts enabledHosts;
        networking.extraHosts = lib.concatStringsSep "\n" (
          map (domain: "127.0.0.1 ${lib.removePrefix "http://" domain}") (
            builtins.attrNames (pangolinHosts enabledHosts)
          )
        );

        thelessone.caddy.vHost."http://theless.one".extraConfig = ''
          root * ${pkgs.theless-dot-one}
          file_server
        '';
        thelessone.caddy.vHost."http://na55l3zepb4kcg0zryqbdnay.theless.one".extraConfig =
          mkFileServer "/var/www/theless.one";

        services.caddy = {
          enable = true;
          enableReload = true;
          environmentFile = config.sops.templates."caddy-users.env".path;
          email = "contact@nanoyaki.space";

          logFormat = ''
            format console
            level INFO
          '';

          globalConfig = ''
            auto_https disable_certs
          '';

          extraConfig = lib.mkForce ''
            (error_handling) {
              handle_errors {
                root * ${pkgs.theless-dot-one}
                try_files {path} /{err.status_code}.html /index.html
                file_server {
                  status 200
                }
              }
            }
          '';

          virtualHosts = mapVhosts enabledHosts;
        };

        systemd.services.caddy = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
        };
      };
    };

  perSystem =
    { pkgs, ... }:

    {
      packages.theless-dot-one = pkgs.fetchFromGitea {
        domain = "git.theless.one";
        owner = "nanoyaki";
        repo = "theless.one";
        rev = "f14f5843d98b3fd4e15c6f2a067305cf3ed5a283";
        hash = "sha256-XWUJ5WUEnvRj1Yuxz5hRjU5iru68P5TKqSl7//6mpAo=";
      };
    };

  flake.overlays.caddy =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) theless-dot-one;
      }
    );
}
