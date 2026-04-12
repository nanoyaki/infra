{
  flake.nixosModules.thelessone-bazarr =
    { config, ... }:

    {
      services.bazarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."bazarr.theless.one" = {
        proxy.port = config.services.bazarr.listenPort;
        useVpn = true;
      };

      systemd.services.borgbackup-job-bazarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.bazarr = {
        repo = "/mnt/raid/borgbackup/bazarr";
        doInit = true;

        paths = "/var/lib/bazarr";

        encryption.mode = "none";
        compression = "zstd";

        startAt = "daily";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 14;
          weekly = 12;
          monthly = -1;
        };
      };
    };
}
