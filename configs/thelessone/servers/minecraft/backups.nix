{
  config,
  ...
}:

{
  sops.secrets = {
    "restic/minecraft-servers" = { };
    "restic/beyond-depth" = { };
  };

  config'.restic.backups.minecraft-servers = {
    repository = "/mnt/raid/backups/minecraft-servers";
    passwordFile = config.sops.secrets."restic/minecraft-servers".path;

    basePath = config.services.minecraft-servers.dataDir;
    paths = [
      "smp/world"
      "oceanBlock2/world"
      "smp-creative/world"
      "lobby/world"
    ];
    exclude = [
      "**/data/DistantHorizons*"
      "smp/world/datapacks"
      "**/*.bak"
    ];

    timerConfig.OnCalendar = "*:0/30";
  };

  config'.restic.backups.beyond-depth = {
    repository = "/mnt/raid/backups/beyond-depth";
    passwordFile = config.sops.secrets."restic/beyond-depth".path;

    basePath = "/home/thelessone/Dokumente/MinecraftServers/Niklas/niklas3";

    timerConfig.OnCalendar = "*:0/30";
  };
}
