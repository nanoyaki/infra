{
  flake.nixosModules.thelessone-minecraftDefaults =
    { pkgs, config, ... }:

    let
      inherit (pkgs) formats;
      inherit (config) plh tpl;
    in

    {
      sec = {
        proxy.sopsFile = ./secrets.yaml;
        proxy.owner = "minecraft";

        bot-token.sopsFile = ./secrets.yaml;
        smp-ledger-postgres-password.sopsFile = ./secrets.yaml;
      };

      tpl."minecraft-secrets.env".file = pkgs.writeEnv "minecraft-secrets.env" {
        DISCORDMCCHAT_BOT_TOKEN = plh.bot-token;
        PROXY_SECRET = plh.proxy;
        SMP_LEDGER_POSTGRES_PASSWORD = plh.smp-ledger-postgres-password;
      };

      users.users.thelessone.extraGroups = [ config.services.minecraft-servers.group ];
      services.minecraft-servers = {
        enable = true;
        eula = true;
        environmentFile = tpl."minecraft-secrets.env".path;
        openFirewall = true;
      };

      services.minecraft-servers'.openVoicechatPorts = true;
      services.minecraft-servers'.serverDefaults = {
        autoStart = true;
        managementSystem = {
          tmux.enable = false;
          systemd-socket.enable = true;
        };
        packageOverrides.jre_headless = pkgs.zulu25;
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
          server-ip = "0.0.0.0";

          spawn-protection = 0;
          view-distance = 12;
          simulation-distance = 12;

          gamemode = "survival";
          difficulty = "hard";
        };

        serverProperties.white-list = true;
        operators.nanoyaki = "433b63b5-5f77-4a9f-b834-8463d520500c";

        symlinks = {
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

          "config/roles.json" = {
            format = formats.json { };
            value = {
              whitelister.overrides.commands."whitelist (add|remove)" = "allow";
              everyone.overrides.commands = {
                "image2map create" = "allow";
                "tick query" = "allow";
              };
            };
          };
        };

        files = {
          "server-icon.png" = "${pkgs.thelessone-minecraft-logomark}/icon.png";

          "config/expresscarts/config.json" = {
            format = formats.json { };
            value = {
              # Multipliers
              maxMinecartSpeed = 64.0;
              waterSpeedMultiplier = 0.5;
              fallDamageMultiplier = 1.0;

              # QOL
              brakeSlowdown = 0.8;
              brakingEnabled = true;
              fastUnpoweredSlowdown = true;

              # Keep behaviour as vanilla as possible
              loadChunks = false;
              blockSpeedMultipliers = { };
            };
          };

          "config/FabricProxy-Lite.toml" = {
            format = formats.toml { };
            value = {
              hackOnlineMode = true;
              hackMessageChain = true;
              disconnectMessage = "Please connect through the proxy.";
              secret = "@PROXY_SECRET@";
            };
          };
        };
      };
    };
}
