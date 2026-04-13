{
  flake.nixosModules.thelessone-bazarr =
    { config, ... }:

    {
      services.bazarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      services.newt.blueprint.private-resources.bazarr = {
        name = "Bazarr";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.bazarr.listenPort;
        udp-ports = "";
        alias = "bazarr.theless.one";
        roles = [ "Arr-Admin" ];
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
