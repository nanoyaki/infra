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

    basePath = "${config.services.minecraft-servers.dataDir}/smp/world";
    exclude = [
      "**/data/DistantHorizons*"
      "datapacks"
      "**/*.bak"
    ];

    timerConfig.OnCalendar = "*:0/30";
  };

  # config'.restic.backups.beyond-depth = {
  #   repository = "/mnt/raid/backups/beyond-depth";
  #   passwordFile = config.sops.secrets."restic/beyond-depth".path;

  #   basePath = "/home/thelessone/Dokumente/MinecraftServers/Niklas/niklas3";

  #   timerConfig.OnCalendar = "*:0/30";
  # };
}
