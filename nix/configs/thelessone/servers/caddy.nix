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
        hasInfix
        mkIf
        elemAt
        splitString
        filterAttrs
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

            useVpn = mkEnableOption "vpn only access";
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
          useACMEHost = mkIf (hasInfix "theless.one" domain) "theless.one";
          listenAddresses = mkIf vHost.useVpn (
            (map
              (
                cidrSuffixed:

                let
                  address = elemAt (splitString "/" cidrSuffixed) 0;
                in

                if hasInfix ":" address then "[${address}]" else address
              )
              (
                config.networking.wg-quick.interfaces.wg0.address or config.networking.wireguard.interfaces.wg0.ips
              )
            )
            ++ [
              "127.0.0.1"
              "[::1]"
            ]
          );
        }
        // (removeAttrs vHost [
          "enable"
          "proxy"
          "extraConfig"
          "useVpn"
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
        networking.firewall.allowedTCPPorts = [
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

        services.caddy = {
          enable = true;
          enableReload = true;
          environmentFile = config.sops.templates."caddy-users.env".path;
          email = "contact@nanoyaki.space";

          logFormat = ''
            format console
            level INFO
          '';

          extraConfig = lib.mkForce ''
            (error_handling) {
              handle_errors {
                root * ${pkgs.thelessDotOne}
                try_files {path} /{err.status_code}.html /index.html
                file_server {
                  status 200
                }
              }
            }
          '';

          virtualHosts =
            let
              # String -> String
              mkFileServer = directory: ''
                root * ${directory}
                file_server * browse
              '';

              # String -> String
              mkRedirect = url: ''
                redir ${url} permanent
              '';
            in

            (mapVhosts enabledHosts)
            // {
              "theless.one".extraConfig = ''
                root * ${pkgs.thelessDotOne}
                file_server
              '';
              "na55l3zepb4kcg0zryqbdnay.theless.one".extraConfig = mkFileServer "/var/www/theless.one";
              "legacyfiles.theless.one".extraConfig = mkFileServer "/var/lib/caddy/files";

              "vappie.space".extraConfig = mkRedirect "https://bsky.app/profile/vappie.space";
              "www.vappie.space".extraConfig = mkRedirect "https://bsky.app/profile/vappie.space";
              "twitter.vappie.space".extraConfig = mkRedirect "https://x.com/vappie_";
            };
        };

        systemd.services.caddy = {
          wants = [
            "network-online.target"
            "copyparty.service"
          ];

          after = [
            "network-online.target"
            "copyparty.service"
          ];
        };

        thelessone.caddy.vHost."restic.theless.one" = {
          proxy.host = "10.0.0.6";
          proxy.port = 8000;
          useVpn = true;
        };
      };
    };

  perSystem =
    { pkgs, ... }:

    {
      packages.thelessDotOne = pkgs.fetchFromGitea {
        domain = "git.theless.one";
        owner = "nanoyaki";
        repo = "theless.one";
        rev = "c98e1b01f036e7bccc249cce444bc1e542efd5b3";
        hash = "sha256-IR9Ml+/WecD+6twUzM3Mzk+CGqrYrkOKt3JHZ/N6fZ4=";
      };
    };

  flake.overlays.caddy =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) thelessDotOne;
      }
    );
}
