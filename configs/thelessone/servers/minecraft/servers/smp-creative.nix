{ pkgs, ... }:

{
  services.minecraft-servers'.servers.smp-creative = {
    enable = true;
    package = pkgs.fabricServers.fabric-1_21_8;
    jvmOpts = "-Xms8G -Xmx8G";

    serverProperties = {
      server-port = 30051;

      gamemode = "creative";
      difficulty = "normal";
      level-seed = "-7952476580899652458";
    };

    # TODO: use a proper permission system
    operators = import ../whitelist.nix;

    gamerules = pkgs.datapackSet.gamerules {
      keepInventory = true;
      doMobSpawning = false;
      mobGriefing = false;
      disableElytraMovementCheck = true;
      disablePlayerMovementCheck = true;
    };

    mods = map (mod: mod.latest) (
      with pkgs.minecraft.fabric.v1_21_8;
      [
        fabric-api
        fabricproxy-lite
        simple-voice-chat
        vmp-fabric
        lithium
        # player-roles
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
        rei
        architectury-api
        cloth-config

        axiom
        carpet
      ]
    );

    datapacks = map (datapack: datapack.latest) (
      with pkgs.minecraft.datapack.v1_21_8;
      [
        dungeons-and-taverns
        joshs-more-foods
        mini-blocks-datapack
      ]
    );

    symlinks."config/voicechat/voicechat-server.properties".value = {
      port = 24455;
      voice_host = "theless.one:24455";
    };
  };
}
