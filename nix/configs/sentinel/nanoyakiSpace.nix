{ withSystem, ... }:

{
  flake.nixosModules.sentinel-nanoyakiSpace =
    {
      pkgs,
      config,
      ...
    }:

    let
      webPkg = "${pkgs.nanoyaki-space}/share/php/nanoyaki-space";
      inherit (config.services.caddy) user;
    in

    {
      sops.secrets.steam-api-key.owner = user;
      sops.secrets.app-secret.owner = user;

      users.users.${user}.extraGroups = [ "nanoyaki-space" ];
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
            env APP_SHARE_DIR "/var/cache/nanoyaki-space"
            env APP_CACHE_DIR "/var/cache/nanoyaki-space"
            env APP_LOG_DIR "/var/log/nanoyaki-space"
            env APP_ENV "prod"

            resolve_root_symlink
          }

          @dotfiles {
            not path /.well-known/*
            path /.*
          }
          redir @dotfiles /
        '';
      };

      systemd.settings.nanoyaki-space."/var/cache/nanoyaki-space".d = {
        user = "nanoyaki-space";
        group = "nanoyaki-space";
        mode = "770";
      };
      systemd.settings.nanoyaki-space."/var/log/nanoyaki-space".d = {
        user = "nanoyaki-space";
        group = "nanoyaki-space";
        mode = "770";
      };

      users.groups.nanoyaki-space = { };
      users.users.nanoyaki-space = {
        isSystemUser = true;
        group = "nanoyaki-space";
      };

      services.phpfpm.pools.nanoyaki-space = {
        user = "nanoyaki-space";
        group = "nanoyaki-space";
        phpPackage = pkgs.php85;
        phpOptions = ''
          memory_limit = 256M
          display_errors = 0
          date.timezone = "Europe/Berlin"
        '';
        settings = {
          "listen.owner" = user;
          "listen.group" = config.services.caddy.group;
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
