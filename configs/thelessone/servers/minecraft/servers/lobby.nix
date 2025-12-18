{ inputs, pkgs, ... }:

{
  services.minecraft-servers'.servers.lobby = {
    enable = true;
    enableReload = true;
    package = pkgs.fabricServers.fabric-1_21_8;
    jvmOpts = "-Xms2G -Xmx2G";

    serverProperties = {
      server-port = 30052;

      gamemode = "adventure";
      difficulty = "normal";

      spawn-protection = 16;
      view-distance = 4;
      simulation-distance = 4;

      level-seed = "-7952476580899652458";
    };

    gamerules = {
      keepInventory = true;
      doMobSpawning = false;
      mobGriefing = false;
      disableElytraMovementCheck = true;
      disablePlayerMovementCheck = true;
      spawnRadius = 32;
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

        carpet
      ]
    );

    datapacks = [
      (pkgs.runCommand "killheal" { inherit (inputs.killheal.packages.x86_64-linux) killheal; } ''
        ln -s $killheal $out
      '')
    ];

    symlinks."config/voicechat/voicechat-server.properties".value = {
      port = 24456;
      voice_host = "theless.one:24456";
    };
  };
}
