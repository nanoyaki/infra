{
  flake.nixosModules.sumire-ntfy-sh =
    { config, ... }:

    let
      cfg = config.services.ntfy-sh;
    in

    {
      services.ntfy-sh = {
        enable = true;
        user = "ntfy-sh";
        group = "ntfy-sh";

        settings = {
          listen-http = "[::1]:2586";
          base-url = "https:://ntfy.serdexmethylpheni.date";

          database-url = "postgres:///ntfy-sh";
          auth-file = "/var/lib/ntfy-sh/user.db";
          attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
          cache-file = "/var/cache/ntfy-sh/cache-file.db";
        };
      };

      systemd.services.ntfy-sh.serviceConfig.CacheDirectory = "ntfy-sh";

      services.caddy.virtualHosts."serdexmethylpheni.date" = {
        useACMEHost = "serdexmethylpheni.date";
        extraConfig = ''
          reverse_proxy [::1]:2586
        '';
      };

      services.postgresql = {
        ensureDatabases = [ cfg.user ];
        ensureUsers = [
          {
            name = cfg.user;
            ensureDBOwnership = true;
          }
        ];
      };
    };
}
