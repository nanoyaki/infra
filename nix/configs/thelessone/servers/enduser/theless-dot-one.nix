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
    in

    {
      services.caddy.extraConfig = lib.mkForce ''
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

      services.caddy.virtualHosts."*.theless.one".extraConfig = ''
        import theless_dot_one 404
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

      sops.secrets."theless-dot-one/secret".owner = user;
      sops.templates."theless-dot-one.env".file = pkgs.writeEnv "theless-dot-one.env.template" {
        APP_SECRET = config.sops.placeholder."theless-dot-one/secret";
      };

      systemd.services.phpfpm-theless-dot-one = {
        serviceConfig.EnvironmentFile = config.sops.templates."theless-dot-one.env".path;
        environment = {
          APP_RUNTIME_OPTIONS = builtins.toJSON { disable_dotenv = true; };
          APP_CACHE_DIR = "/var/cache/theless-dot-one";
          DEFAULT_URI = "https://theless.one";
        };

        preStart = ''
          rm -rf "$APP_CACHE_DIR/prod"
          ${lib.getExe pkgs.php85} ${webPkg}/bin/console cache:clear --env=prod --no-debug
        '';
      };

      services.phpfpm.pools.theless-dot-one = {
        inherit user group;
        phpPackage = pkgs.php85;
        phpOptions = ''
          memory_limit = 256M
          display_errors = 0
          error_reporting = E_ALL
          date.timezone = "Europe/Berlin"
        '';

        phpEnv = {
          APP_ENV = "prod";
          APP_SECRET = "$APP_SECRET";
          APP_SHARE_DIR = "$APP_CACHE_DIR";
          APP_CACHE_DIR = "$APP_CACHE_DIR";
          APP_LOG_DIR = "/var/log/theless-dot-one";
          APP_RUNTIME_OPTIONS = "$APP_RUNTIME_OPTIONS";
          DEFAULT_URI = "$DEFAULT_URI";
        };

        settings = {
          "listen.owner" = user;
          "listen.group" = group;
          "listen.mode" = "0660";
          "pm" = "dynamic";
          "pm.max_children" = 5;
          "pm.start_servers" = 1;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 5;
          "pm.max_requests" = 50;
          "php_admin_value[error_log]" = "stderr";
          "php_admin_flag[log_errors]" = true;
          "catch_workers_output" = true;
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
