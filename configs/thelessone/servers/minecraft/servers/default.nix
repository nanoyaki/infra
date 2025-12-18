{ pkgs, config, ... }:

let
  inherit (pkgs) formats;
in

{
  imports = [
    ./lobby.nix
    ./proxy.nix
    ./smp.nix
    ./smp-creative.nix
    ./smp2.nix
  ];

  sops.secrets.proxy.sopsFile = ./secrets.yaml;
  sops.secrets.bot-token.sopsFile = ./secrets.yaml;

  sops.templates."minecraft-secrets.env".file =
    (formats.keyValue { }).generate "minecraft-secrets.env"
      {
        DISCORDMCCHAT_BOT_TOKEN = config.sops.placeholder.bot-token;
        FABRIC_PROXY_SECRET = config.sops.placeholder.proxy;
      };

  services.minecraft-servers = {
    enable = true;
    eula = true;
    environmentFile = config.sops.templates."minecraft-secrets.env".path;
    openFirewall = true;
  };

  services.minecraft-servers'.openVoicechatPorts = true;
  services.minecraft-servers'.serverDefaults = {
    autoStart = true;
    packageOverrides = {
      jre_headless = pkgs.zulu21;
    };
    jvmOpts = "-Xms16G -Xmx16G";
    appendJvmOpts =
      # Use ZGC
      "-XX:+UseZGC -XX:AllocatePrefetchStyle=1 -XX:-ZProactive"
      + " -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine"
      + " -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1"
      + " -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M"
      + " -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000"
      + " -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem"
      + " -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority"
      + " -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3";

    serverProperties = {
      server-ip = "127.0.0.1";

      spawn-protection = 0;
      view-distance = 12;
      simulation-distance = 12;

      gamemode = "survival";
      difficulty = "hard";
    };

    serverProperties.white-list = true;
    whitelist = import ./whitelist.nix;
    operators.nanoyaki = "433b63b5-5f77-4a9f-b834-8463d520500c";

    symlinks = {
      "server-icon.png" = ../icon.png;
      "config/voicechat/voicechat-server.properties" = {
        format = formats.keyValue { };
        value = {
          bind_address = "";
          max_voice_distance = 64.0;
          crouch_distance_multiplier = 0.75;
          whisper_distance_multiplier = 0.5;
          codec = "VOIP";
          mtu_size = 1024;
          keep_alive = 1000;
          enable_groups = true;
          allow_recording = true;
          spectator_interaction = false;
          spectator_player_possession = false;
          force_voice_chat = false;
          login_timeout = 10000;
          broadcast_range = -1.0;
          allow_pings = true;
        };
      };
    };

    files."config/FabricProxy-Lite.toml" = {
      format = formats.toml { };
      value = {
        hackOnlineMode = true;
        hackMessageChain = true;
        disconnectMessage = "Please connect through the proxy.";
        secret = "@FABRIC_PROXY_SECRET@";
      };
    };

    # player-roles is disabled due to crashes
    # symlinks."config/roles.json" = {
    #   format = formats.json { };
    #   value = {
    #     whitelister.overrides.commands."whitelist (add|remove)" = "allow";
    #     everyone.overrides.commands = {
    #       "image2map create" = "allow";
    #       "tick query" = "allow";
    #     };
    #   };
    # };
  };

  # Additional, non-nixified minecraft servers
  networking.firewall.allowedTCPPorts = [
    25566
    25567
  ];
  networking.firewall.allowedUDPPorts = [
    25566
    25567
  ];
}
