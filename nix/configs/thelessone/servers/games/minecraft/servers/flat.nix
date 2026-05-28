{
  flake.nixosModules.thelessone-minecraftFlat =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    {
      systemd.services.minecraft-server-creative-flat.wantedBy = lib.mkForce [ "server-services.target" ];
      services.minecraft-servers'.servers.creative-flat = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_21_11;
        jvmOpts = "-Xms8G -Xmx8G";

        serverProperties = {
          server-port = 30054;

          gamemode = "creative";
          difficulty = "normal";
          level-seed = "-7952476580899652458";

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

        # TODO: use a proper permission system
        operators = config.services.minecraft-servers'.serverDefaults.whitelist;

        gamerules = {
          # Creative specific
          keep_inventory = true;
          spawn_mobs = false;
          mob_griefing = false;

          # Disable movement checks due
          # to server upload speed limits
          elytra_movement_check = false;
          player_movement_check = false;
        };

        mods = map (mod: mod.latest) (
          with pkgs.minecraft.fabric.v1_21_11;
          [
            fabric-api
            fabricproxy-lite
            vmp-fabric
            lithium
            player-roles
            no-chat-reports
            krypton
            c2me-fabric
            image2map
            netherportalfix
            balm
            ferrite-core
            scalablelux
            do-a-barrel-roll
            cicada
            servux
            architectury-api
            cloth-config
            yacl
            # express-carts

            axiom
            carpet

            # use jei as long as rei isn't
            # supported for mc 1.21.11
            rei
          ]
        );

        datapacks = map (datapack: datapack.latest) (
          with pkgs.minecraft.datapack.v1_21_11;
          [
            dungeons-and-taverns
            # joshs-more-foods
            mini-blocks-datapack
          ]
        );
      };
    };
}
