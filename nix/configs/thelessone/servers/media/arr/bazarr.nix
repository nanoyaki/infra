{
  flake.nixosModules.thelessone-bazarr =
    { lib, config, ... }:

    {
      systemd.services.bazarr.wantedBy = lib.mkForce [ "server-services.nix" ];
      services.bazarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."bazarr.theless.one" = {
        proxy.port = config.services.bazarr.listenPort;
        pangolin.name = "Bazarr";
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
