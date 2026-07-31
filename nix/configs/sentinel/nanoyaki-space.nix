{ inputs, ... }:

{
  flake.nixosModules.sentinel-nanoyaki-space =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config) dmn;

      webPkg = "${pkgs.nanoyaki-space}/share/php/nanoyaki-space";
      inherit (config.services.caddy) user group;
      php = pkgs.php85.withExtensions ({ enabled, all }: enabled ++ (with all; [ redis ]));
      environment = {
        APP_ENV = "prod";
        APP_DEBUG = "false";
        APP_SECRET = config.sops.placeholder."nanoyaki-space/secret";
        APP_RUNTIME_OPTIONS = builtins.toJSON { disable_dotenv = true; };
        APP_CACHE_DIR = "/var/cache/nanoyaki-space";
        APP_SHARE_DIR = "/var/cache/nanoyaki-space";
        APP_LOG_DIR = "/var/log/nanoyaki-space";
        DEFAULT_URI = "https://${dmn.nanoyaki-space}";
        REDIS_DSN = "redis://${config.services.redis.servers.nanoyaki-space.unixSocket}";
        STEAM_API_KEY = config.sops.placeholder."nanoyaki-space/steam-api-key";
        CHROMIUM_BIN = lib.getExe' pkgs.nanoyaki-space.passthru.dependencies "chromium";
        CHROME_DEVEL_SANDBOX = "/run/wrappers/bin/__chromium-suid-sandbox";
      };
    in

    {
      dmn.nanoyaki-space = "nanoyaki.space";

      sentinel.caddy.host.${dmn.nanoyaki-space} = {
        hosts = [ "hanakretzer.de" ];
        config = ''
          root * ${webPkg}/public

          encode zstd gzip
          file_server

          php_fastcgi unix/${config.services.phpfpm.pools.nanoyaki-space.socket} {
            root ${webPkg}/public
            capture_stderr
            resolve_root_symlink
          }

          redir /.* /
        '';
      };

      systemd.tmpfiles.settings.nanoyaki-space = {
        "/var/cache/nanoyaki-space".d = {
          inherit user group;
          mode = "770";
        };

        "/var/log/nanoyaki-space".d = {
          inherit user group;
          mode = "770";
        };
      };

      # To render the zZ emoji properly in the embed image
      fonts.packages = [ pkgs.twemoji-color-font ];
      fonts.fontconfig.enable = true;
      fonts.fontconfig.defaultFonts.emoji = [ "Twitter Color Emoji" ];

      # Necessary to screenshot the rendered twig page
      security.wrappers.__chromium-suid-sandbox = {
        source = "${pkgs.ungoogled-chromium.sandbox}/bin/__chromium-suid-sandbox";
        owner = "root";
        group = "root";
        setuid = true;
      };

      sops.secrets."nanoyaki-space/steam-api-key" = { };
      sops.secrets."nanoyaki-space/secret" = { };
      sops.templates."nanoyaki-space.env".file = pkgs.writeEnv "nanoyaki-space.env.template" environment;

      systemd.services.phpfpm-nanoyaki-space = {
        serviceConfig.EnvironmentFile = config.sops.templates."nanoyaki-space.env".path;
        preStart = ''
          rm -rf "$APP_CACHE_DIR/$APP_ENV"
          ${lib.getExe php} ${webPkg}/bin/console cache:warm
          chown -R ${user}:${group} "$APP_CACHE_DIR"
        '';
      };

      services.phpfpm.pools.nanoyaki-space = {
        inherit user group;
        phpPackage = php;

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

      services.redis.servers.nanoyaki-space = {
        inherit user group;
        enable = true;
        port = 0;
      };
    };

  flake.overlays.nanoyaki-space = final: _: {
    nanoyaki-space = final.callPackage (import "${inputs.nanoyaki-space}/package.nix") { };
  };
}
