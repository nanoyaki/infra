{
  config,
  ...
}:

{
  sops.secrets = {
    "restic/smp" = { };
    "restic/beyond-depth" = { };
  };

  config'.restic.backups.smp = {
    repository = "/mnt/raid/backups/smp";
    passwordFile = config.sops.secrets."restic/smp".path;

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
