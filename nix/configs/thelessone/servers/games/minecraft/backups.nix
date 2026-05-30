{
  flake.nixosModules.thelessone-minecraftBackups =
    {
      config,
      ...
    }:

    {
      thelessone.backups.nix-minecraft.paths = [ config.services.minecraft-servers.dataDir ];
      thelessone.backups.nix-minecraft.exclude = [
        "${config.services.minecraft-servers.dataDir}/*/world/datapacks/**"
        "${config.services.minecraft-servers.dataDir}/**/*.bak"
      ];
    };
}
