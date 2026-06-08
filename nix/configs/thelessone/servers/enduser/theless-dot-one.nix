{ withSystem, ... }:

{
  flake.nixosModules.thelessone-theless-dot-one =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      webPkg = "${pkgs.theless-dot-one}/share/php/theless-dot-one";
      inherit (config.services.caddy) user group;
      environment = {
        APP_ENV = "prod";
        APP_SECRET = config.sops.placeholder."theless-dot-one/secret";
        APP_CACHE_DIR = "/var/cache/theless-dot-one";
        APP_SHARE_DIR = "/var/cache/theless-dot-one";
        APP_LOG_DIR = "/var/log/theless-dot-one";
        APP_RUNTIME_OPTIONS = builtins.toJSON { disable_dotenv = true; };
        DEFAULT_URI = "https://theless.one";
      };
    in

    {
      services.caddy.extraConfig = ''
        (theless_dot_one) {
          root * ${webPkg}/public

          encode zstd gzip
          file_server

          php_fastcgi unix/${config.services.phpfpm.pools.theless-dot-one.socket} {
            root ${webPkg}/public
            header_up X-HTTP-Error {args[0]}

            capture_stderr
            resolve_root_symlink
          }

          redir /.* /
        }

        (error_handling) {
          handle_errors {
            import theless_dot_one {http.error.status_code}
          }
        }
      '';

      thelessone.caddy.vHost."theless.one".extraConfig = ''
        import theless_dot_one ""
      '';

      systemd.tmpfiles.settings.theless-dot-one = {
        "/var/log/theless-dot-one".d = {
          inherit user group;
          mode = "770";
        };
        "/var/cache/theless-dot-one".d = {
          inherit user group;
          mode = "770";
        };
      };

      sops.secrets."theless-dot-one/secret" = { };
      sops.templates."theless-dot-one.env".file =
        pkgs.writeEnv "theless-dot-one.env.template" environment;

      systemd.services.phpfpm-theless-dot-one = {
        serviceConfig.EnvironmentFile = config.sops.templates."theless-dot-one.env".path;
        preStart = ''
          rm -rf "$APP_CACHE_DIR/$APP_ENV"
          ${lib.getExe pkgs.php85} ${webPkg}/bin/console cache:warm
          chown -R ${user}:${group} "$APP_CACHE_DIR"
        '';
      };

      services.phpfpm.pools.theless-dot-one = {
        inherit user group;
        phpPackage = pkgs.php85;

        phpEnv = lib.mapAttrs (name: _: "\$${name}") environment;
        settings = {
          # Access
          "listen.owner" = user;
          "listen.group" = group;
          "listen.mode" = "0660";

          # Performance
          "pm" = "dynamic";
          "pm.max_children" = 10;
          "pm.start_servers" = 3;
          "pm.min_spare_servers" = 2;
          "pm.max_spare_servers" = 5;
          "pm.max_requests" = 500;
          "request_terminate_timeout" = "30s";
          "php_admin_value[memory_limit]" = "396M";

          # App config
          "php_admin_value[date.timezone]" = "Europe/Berlin";

          # Logging
          "php_admin_value[error_reporting]" = "E_ALL";
          "php_admin_flag[log_errors]" = true;
          "php_admin_flag[display_errors]" = false;
          "catch_workers_output" = true;
          "decorate_workers_output" = false;
        };
      };
    };

  flake.overlays.theless-dot-one =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { inputs', ... }:

      {
        inherit (inputs'.theless-dot-one.packages) theless-dot-one;
      }
    );
}
