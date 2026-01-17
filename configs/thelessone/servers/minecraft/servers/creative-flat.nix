{ lib, config, ... }:

{
  services.minecraft-servers'.servers.creative-flat =
    lib.recursiveUpdate config.services.minecraft-servers'.servers.smp-creative
      {
        enable = true;

        serverProperties = {
          server-port = 30054;

          level-type = "minecraft\\:flat";
          generator-settings = builtins.toJSON {
            biome = "minecraft:plains";
            layers = [
              {
                block = "minecraft:bedrock";
                height = 1;
              }
              {
                block = "minecraft:dirt";
                height = 2;
              }
              {
                block = "minecraft:grass_block";
                height = 1;
              }
            ];
          };
        };

        symlinks."config/voicechat/voicechat-server.properties".value = {
          port = 24456;
          voice_host = "theless.one:24456";
        };
      };
}
