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

        rm -rf "$APP_CACHE_DIR/prod"
        ${lib.getExe pkgs.php85} ${webPkg}/bin/console cache:clear --env=prod --no-debug
      '';

      sentinel.caddy.host."nanoyaki.space".config = ''
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
          env CHROMIUM_BIN "${lib.getExe' pkgs.nanoyaki-space.passthru.dependencies "chromium"}"

          capture_stderr
          resolve_root_symlink
        }

        @dotfiles {
          not path /.well-known/*
          path /.*
        }
        redir @dotfiles /
      '';

      services.traefik.dynamicConfigOptions.http = {
        routers.nanoyaki-space = {
          rule = "Host(`nanoyaki.space`)";
          entryPoints = [ "websecure" ];
          service = "nanoyaki-space";
          tls = { };
        };

        services.nanoyaki-space.loadBalancer.servers = [
          { url = "http://127.0.0.1:8006"; }
        ];
      };

      systemd.tmpfiles.settings.nanoyaki-space."/var/cache/nanoyaki-space".d = {
        inherit (config.services.caddy) user group;
        mode = "770";
      };
      systemd.tmpfiles.settings.nanoyaki-space."/var/log/nanoyaki-space".d = {
        inherit (config.services.caddy) user group;
        mode = "770";
      };

      # To render the zZ emoji properly in the embed image
      fonts.packages = [ pkgs.twemoji-color-font ];
      fonts.fontconfig.enable = true;
      fonts.fontconfig.defaultFonts.emoji = [ "Twitter Color Emoji" ];

      # Necessary to screenshot the rendered twig page
      security.wrappers."__chromium-suid-sandbox" = {
        source = "${pkgs.ungoogled-chromium.sandbox}/bin/__chromium-suid-sandbox";
        owner = "root";
        group = "root";
        setuid = true;
      };
      systemd.services.phpfpm-nanoyaki-space.environment.CHROME_DEVEL_SANDBOX =
        "/run/wrappers/bin/__chromium-suid-sandbox";

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
