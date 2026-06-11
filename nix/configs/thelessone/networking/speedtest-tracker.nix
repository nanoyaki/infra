{
  flake.nixosModules.thelessone-speedtest-tracker =
    { lib, config, ... }:

    let
      inherit (lib) mkEnableOption;
      inherit (config) prt dmn sec;

      cfg = config.services.speedtest-tracker;
    in

    {
      options.services.speedtest-tracker.acknowledgeUnfree = mkEnableOption "whether to acknowledge the usage of unfree packages";

      config = {
        warnings = lib.mkIf (!cfg.acknowledgeUnfree) [
          "Speedtest-tracker uses the unfree package `ookla-speedtest`. Set `speedtest-tracker.acknowledgeUnfree` to disable this warning."
        ];

        prt.speedtest-internal = 8001;
        dmn.speedtest-tracker = "speedtest.theless.one";

        sec."speedtest-tracker/app-key".owner = cfg.user;

        users.users.${cfg.user}.extraGroups = [ "no-reply" ];
        services.speedtest-tracker = {
          enable = true;
          user = "speedtest-tracker";
          group = cfg.user;

          settings = {
            APP_KEY_FILE = sec."speedtest-tracker/app-key".path;

            APP_URL = "https://${dmn.speedtest-tracker}";
            APP_TIMEZONE = "Europe/Vienna";
            DISPLAY_TIMEZONE = "Europe/Vienna";
            PUBLIC_DASHBOARD = true;
            SPEEDTEST_INTERFACE = "enp9s0";
            SPEEDTEST_EXTERNAL_IP_URL = "https://am.i.mullvad.net/ip";
            # Every 6 hours
            SPEEDTEST_SCHEDULE = "0 */6 * * *";

            MAIL_MAILER = "smtp";
            MAIL_HOST = dmn.mail;
            MAIL_PORT = prt.smtp-tls;
            MAIL_USERNAME = "no-reply@${dmn.self}";
            MAIL_PASSWORD_FILE = sec.no-reply-password.path;
            MAIL_FROM_NAME = "Speedtest Theless.one";

            LOG_CHANNEL = "syslog";
          };
        };

        services.phpfpm.pools.speedtest-tracker.settings = {
          "php_admin_value[date.timezone]" = "Europe/Vienna";
          # Logging
          "php_admin_value[error_reporting]" = "E_ALL";
          "php_admin_flag[log_errors]" = true;
          "php_admin_flag[display_errors]" = false;
          "catch_workers_output" = true;
          "decorate_workers_output" = false;
        };

        users.users.${config.services.caddy.user}.extraGroups = [ cfg.group ];

        services.caddy.extraConfig = ''
          (speedtest) {
            root * ${cfg.package}/public

            encode zstd gzip
            file_server

            php_fastcgi unix/${config.services.phpfpm.pools.speedtest-tracker.socket} {
              root ${cfg.package}/public
              capture_stderr
              resolve_root_symlink
            }
          }
        '';

        thelessone.caddy.vHost."http://localhost:${toString prt.speedtest-internal}".extraConfig = ''
          import speedtest
        '';

        thelessone.caddy.vHost.${dmn.speedtest-tracker} = {
          extraConfig = ''
            import speedtest
          '';
          useTailnet = true;
        };

        nixpkgs.allowUnfreeNames = [ "ookla-speedtest" ];
      };
    };
}
