{ pkgs, ... }:

{
  services.minecraft-servers'.servers.smp2 = {
    enable = false;
    enableReload = true;
    package = pkgs.fabricServers.fabric-1_21_8;
    jvmOpts = "-Xms2G -Xmx16G";

    serverProperties = {
      server-port = 30053;

      difficulty = "hard";

      spawn-protection = 0;
      view-distance = 32;
      simulation-distance = 32;
    };

    gamerules = {
      locatorBar = false;
      disableElytraMovementCheck = true;
      disablePlayerMovementCheck = true;
      playersSleepingPercentage = 33;
    };

    mods = map (mod: mod.latest) (
      with pkgs.minecraft.fabric.v1_21_8;
      [
        fabric-api
        fabricproxy-lite
        lithium
        no-chat-reports
        krypton
        c2me-fabric
        balm
        ferrite-core
        scalablelux
        cicada
        servux
        architectury-api
        cloth-config

        # use jei as long as rei isn't
        # supported for mc 1.21.11
        # rei
        jei
      ]
    );

    datapacks = [
      (pkgs.fetchzip {
        url = "https://cdn.modrinth.com/data/biXJOpKz/versions/auk9B0OQ/MTimer.zip";
        stripRoot = false;
        hash = "sha256-qwmMECpNyjSaVm/njGQyw08hpTmT8EKFxC4tpSfXotE=";
      })
    ];

    operators = {
      Angreiferr = "885ca84d-669f-4cd7-a7a8-273d94fb7cd4";
      einfach_calle = "3210afd0-4620-4120-9f49-d5379bf8e0b2";
    };
  };
}
