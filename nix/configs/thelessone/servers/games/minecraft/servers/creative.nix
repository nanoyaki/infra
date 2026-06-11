{
  flake.nixosModules.thelessone-minecraftCreative =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.minecraft-server-creative = 30051;
      prt.minecraft-server-creative-vc = 24455;
      dmn.creative = "creative.theless.one";

      systemd.services.minecraft-server-smp-creative.wantedBy = lib.mkForce [ "server-services.target" ];
      services.minecraft-servers'.servers.smp-creative = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_21_11;
        jvmOpts = "-Xms8G -Xmx8G";

        serverProperties = {
          server-port = prt.minecraft-server-creative;

          gamemode = "creative";
          difficulty = "normal";
          level-seed = "-7952476580899652458";
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
            simple-voice-chat
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
            joshs-more-foods
            mini-blocks-datapack
          ]
        );

        symlinks."config/voicechat/voicechat-server.properties".value = {
          port = prt.minecraft-server-creative-vc;
          voice_host = "${dmn.self}:${toString prt.minecraft-server-creative-vc}";
        };
      };
    };
}
