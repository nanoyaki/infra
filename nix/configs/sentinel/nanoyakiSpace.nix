{ withSystem, ... }:

{
  flake.nixosModules.sentinel-nanoyakiSpace =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      webPkg = "${pkgs.nanoyaki-space}/share/php/nanoyaki-space";
      inherit (config.services.caddy) user;
      runtimeOptsFile = pkgs.writeText "app_runtime_options.json" (
        builtins.toJSON {
          disable_dotenv = true;
        }
      );
    in

    {
      sops.secrets.steam-api-key.owner = user;
      sops.secrets.app-secret.owner = user;

      systemd.services.caddy.preStart = ''
        export APP_RUNTIME_OPTIONS="$(cat ${runtimeOptsFile})"
        export DEFAULT_URI="https://nanoyaki.space"
        export APP_LOG_DIR="/var/log/nanoyaki-space"
        export APP_CACHE_DIR="/var/cache/nanoyaki-space"
        export APP_SHARE_DIR="/var/cache/nanoyaki-space"
        ${lib.getExe pkgs.php85} ${webPkg}/bin/console cache:warmup --env=prod --no-debug
      '';
      services.caddy.virtualHosts."nanoyaki.space" = {
        useACMEHost = "nanoyaki.space";
        extraConfig = ''
          root * ${webPkg}/public

          encode zstd gzip
          file_server

          php_fastcgi unix/${config.services.phpfpm.pools.nanoyaki-space.socket} {
            root ${webPkg}/public

            env APP_SECRET {file.${config.sops.secrets.app-secret.path}}
            env STEAM_API_KEY {file.${config.sops.secrets.steam-api-key.path}}
            env APP_ENV "prod"
            env APP_SHARE_DIR "/var/cache/nanoyaki-space"
            env APP_CACHE_DIR "/var/cache/nanoyaki-space"
            env APP_LOG_DIR "/var/log/nanoyaki-space"
            env DEFAULT_URI "https://nanoyaki.space"
            env APP_RUNTIME_OPTIONS {file.${runtimeOptsFile}}

            capture_stderr
            resolve_root_symlink
          }

          @dotfiles {
            not path /.well-known/*
            path /.*
          }
          redir @dotfiles /
        '';
      };

      systemd.tmpfiles.settings.nanoyaki-space."/var/cache/nanoyaki-space".d = {
        inherit (config.services.caddy) user group;
        mode = "770";
      };
      systemd.tmpfiles.settings.nanoyaki-space."/var/log/nanoyaki-space".d = {
        inherit (config.services.caddy) user group;
        mode = "770";
      };

      services.phpfpm.pools.nanoyaki-space = {
        inherit (config.services.caddy) user group;
        phpPackage = pkgs.php85;
        phpOptions = ''
          memory_limit = 256M
          display_errors = 0
          error_reporting = E_ALL
          date.timezone = "Europe/Berlin"
        '';
        settings = {
          "listen.owner" = user;
          "listen.group" = config.services.caddy.group;
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

  flake.overlays.nanoyaki-space =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { inputs', ... }:

      {
        inherit (inputs'.nanoyaki-space.packages) nanoyaki-space;
      }
    );
}
