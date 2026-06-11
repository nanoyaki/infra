{ withSystem, ... }:

{
  flake.nixosModules.thelessone-nanoyakiEvents =
    {
      pkgs,
      config,
      ...
    }:

    let
      webPkg = "${pkgs.discord-events-to-ics}/share/php/discord-events-to-ics";
      home = "/var/lib/caddy/nanoyaki-events";
      inherit (config.services.caddy) user;
      inherit (config) sec;
    in

    # TODO: move to sentinel
    {
      sec = {
        "calendar/guildId".owner = user;
        "calendar/botToken".owner = user;
      };

      users.users.${user}.extraGroups = [ "nanoyaki-events" ];
      thelessone.caddy.vHost."events.nanoyaki.space".extraConfig = ''
        root * ${webPkg}/public

        encode zstd gzip
        file_server

        php_fastcgi unix/${config.services.phpfpm.pools.nanoyaki-events.socket} {
          root ${webPkg}/public

          env GUILD_ID {file.${sec."calendar/guildId".path}}
          env BOT_TOKEN {file.${sec."calendar/botToken".path}}
          env CACHE_DIR "${home}/cache"
          env LOG_PATH "${home}/logs"
          env LOG_LEVEL "info"

          resolve_root_symlink
        }

        @dotfiles {
          not path /.well-known/*
          path /.*
        }
        redir @dotfiles /
      '';

      systemd.tmpfiles.settings."10-nanoyaki-events" = {
        "${home}/cache".d = {
          user = "nanoyaki-events";
          group = "nanoyaki-events";
          mode = "0770";
        };

        "${home}/logs".d = {
          user = "nanoyaki-events";
          group = "nanoyaki-events";
          mode = "0770";
        };
      };

      users.groups.nanoyaki-events = { };
      users.users.nanoyaki-events = {
        isSystemUser = true;
        group = "nanoyaki-events";
        inherit home;
        homeMode = "770";
      };

      services.phpfpm.pools.nanoyaki-events = {
        user = "nanoyaki-events";
        phpPackage = pkgs.php84;
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

  perSystem =
    { inputs', ... }:

    {
      packages.discord-events-to-ics = inputs'.discord-events-to-ics.packages.default.overrideAttrs {
        vendorHash = "sha256-w2dmfX2H0NdouC1Z4YCjirNgJK67cOSQVt3nu7bJ8xY=";
      };
    };

  flake.overlays.discord-events-to-ics =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) discord-events-to-ics;
      }
    );
}
