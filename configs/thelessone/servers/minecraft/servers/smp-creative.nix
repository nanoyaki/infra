{ pkgs, ... }:

{
  services.minecraft-servers'.servers.smp-creative = {
    enable = true;
    package = pkgs.fabricServers.fabric-1_21_11;
    jvmOpts = "-Xms8G -Xmx8G";

    serverProperties = {
      server-port = 30051;

      gamemode = "creative";
      difficulty = "normal";
      level-seed = "-7952476580899652458";
    };

    # TODO: use a proper permission system
    operators = import ./whitelist.nix;

    gamerules = {
      # Creative specific
      keep_inventory = true;
      spawn_mobs = false;
      mob_griefing = false;

      # Disable movement checks due
      # to server upload speed limits
      elytra_movement_check = false;
      player_movement_check = false;

      # Minecart speed
      "ace:speed_player" = 64;
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
        audaki-cart-engine

        axiom
        carpet

        # use jei as long as rei isn't
        # supported for mc 1.21.11
        # rei
        jei
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

    symlinks."config/voicechat/voicechat-server.properties".value = {
      port = 24455;
      voice_host = "theless.one:24455";
    };
  };
}
