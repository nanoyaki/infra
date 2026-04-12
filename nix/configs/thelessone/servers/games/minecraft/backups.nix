{
  flake.nixosModules.thelessone-minecraftBackups =
    {
      config,
      ...
    }:

    {
      systemd.services.borgbackup-job-nix-minecraft.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.nix-minecraft = {
        repo = "/mnt/raid/borgbackup/nix-minecraft";
        doInit = true;

        paths = config.services.minecraft-servers.dataDir;
        patterns = [
          "+ */"
          "+ */world/**"
          "- */world/datapacks/**"
          "- */**"
          "- **/*.bak"
          "- **"
        ];

        encryption.mode = "none";
        compression = "zstd";

        startAt = "*:0/30";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 14;
          weekly = 12;
          monthly = -1;
        };
      };

      systemd.services.borgbackup-job-manual-mc.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.manual-mc = {
        repo = "/mnt/raid/borgbackup/manual-mc";
        doInit = true;

        paths = "/home/thelessone/Dokumente/MinecraftServers";

        encryption.mode = "none";
        compression = "zstd";

        startAt = "*:0/30";
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
