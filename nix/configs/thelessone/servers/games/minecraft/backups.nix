{
  flake.nixosModules.thelessone-minecraftBackups =
    {
      config,
      ...
    }:

    {
      services.borgbackup.jobs.nix-minecraft = {
        repo = "thelessone-borg@10.0.0.6:nix-minecraft";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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

      services.borgbackup.jobs.manual-mc = {
        repo = "thelessone-borg@10.0.0.6:manual-mc";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
