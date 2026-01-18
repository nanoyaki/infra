{ inputs, pkgs, ... }:

{
  services.minecraft-servers'.servers.lobby = {
    enable = true;
    enableReload = true;
    package = pkgs.fabricServers.fabric-1_21_11;
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
      # Lobby specific
      keep_inventory = true;
      mob_griefing = false;
      spawn_mobs = false;
      respawn_radius = 32;

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
        express-carts

        carpet

        # use jei as long as rei isn't
        # supported for mc 1.21.11
        # rei
        jei
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
