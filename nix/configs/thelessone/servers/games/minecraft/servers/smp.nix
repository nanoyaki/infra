{
  flake.nixosModules.thelessone-minecraftSmp =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (pkgs) formats;
      inherit (config.services.minecraft-servers.managementSystem.systemd-socket) stdinSocket;
    in

    {
      systemd.services.minecraft-server-smp.wantedBy = lib.mkForce [ "server-services.target" ];
      services.minecraft-servers'.servers.smp = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_21_11;

        extraStopPre = ''
          echo "say Server restart in 10 seconds" > ${stdinSocket.path "smp"}
          sleep 10
        '';

        serverProperties = {
          server-port = 30050;
          initial-enabled-packs = "vanilla";
          difficulty = "normal";
        };

        gamerules = {
          # SMP improvements
          locator_bar = false;
          players_sleeping_percentage = 33;

          # Disable movement checks due
          # to server upload speed limits
          elytra_movement_check = false;
          player_movement_check = false;
        };

        datapacks = map (datapack: datapack.latest) (
          with pkgs.minecraft.datapack.v1_21_11;
          [
            dungeons-and-taverns
            mini-blocks-datapack
            joshs-more-foods
          ]
        );

        mods = map (mod: mod.latest) (
          with pkgs.minecraft.fabric.v1_21_11;
          [
            # libraries
            architectury-api
            cloth-config
            yacl
            fabric-api
            fabric-language-kotlin
            balm
            cicada

            # velocity
            fabricproxy-lite
            simple-voice-chat

            # optimization
            vmp-fabric
            lithium
            scalablelux
            krypton
            c2me-fabric
            ferrite-core

            # qol
            no-chat-reports
            image2map
            bluemap
            bluemap-sign-markers
            discord-mc-chat
            netherportalfix
            do-a-barrel-roll
            servux # for litematica, i think
            express-carts
            carpet
            rei

            # admin
            player-roles
            ledger
            invview
          ]
        );

        files."config/discord-mc-chat.json" = {
          format = formats.json { };
          value = {
            generic = {
              language = "en_us";
              botToken = "@DISCORDMCCHAT_BOT_TOKEN@";
              channelId = "1395405287984201738";
              adminsIds = [
                "1063583541641871440"
                "222458973876387841"
              ];

              avatarApi = "https://visage.surgeplay.com/bust/{player_uuid}.png";
              broadcastPlayerCommandExecution = false;
              broadcastSlashCommandExecution = false;
              whitelistRequiresAdmin = false;
              announceHighMspt = false;
              excludedCommands = [ ".*" ];
            };
          };
        };

        symlinks = {
          "config/ledger.toml" = {
            format = formats.toml { };
            value = {
              # Once ledger databases gets a 1.21.11 release
              # database_extensions = {
              #   database = "POSTGRESQL";
              #   url = "localhost:${toString config.services.postgresql.settings.port}/smp-ledger";
              #   username = "smp-ledger";
              #   password = "@SMP_LEDGER_POSTGRES_PASSWORD@";
              #   properties = [
              #     "serverTimezone=${toString config.time.timeZone}"
              #   ];
              # };

              search.timeZone = config.time.timeZone;

              # Allow clients to give us data
              networking.networking = true;
            };
          };

          "config/voicechat/voicechat-server.properties".value = {
            port = 24454;
            voice_host = "theless.one:24454";
          };

          "config/bluemap/core.conf" = {
            format = formats.hocon { };
            value = {
              accept-download = true;
              scan-for-mod-resources = true;
              data = "bluemap";
              render-thread-count = 12;
              metrics = false;
              log.file = "logs/bluemap.log";
              log.append = true;
            };
          };

          "config/bluemap/plugin.conf" = {
            format = formats.hocon { };
            value = {
              live-player-markers = true;
              hidden-game-modes = [ "spectator" ];
              hide-vanished = true;
              hide-invisible = true;
              hide-sneaking = true;
              hide-below-sky-light = 0;
              hide-below-block-light = 0;
              hide-different-world = false;
              skin-download = true;
              player-render-limit = -1;
              full-update-interval = 720;
            };
          };

          "config/bluemap/webapp.conf" = {
            format = formats.hocon { };
            value = {
              enabled = true;
              webroot = "bluemap/web";
              update-settings-file = true;
              use-cookies = true;
              enable-free-flight = true;
              default-to-flat-view = false;
              min-zoom-distance = 5;
              max-zoom-distance = 100000;
              resolution-default = 1;

              hires-slider-max = 500;
              hires-slider-default = 100;
              hires-slider-min = 0;

              lowres-slider-max = 7000;
              lowres-slider-default = 2000;
              lowres-slider-min = 500;

              scripts = [ ];
              styles = [ ];
            };
          };

          "config/bluemap/webserver.conf" = {
            format = formats.hocon { };
            value = {
              enabled = true;
              webroot = "bluemap/web";
              port = 8100;

              log = {
                file = "logs/bluemap.log";
                append = true;
                format = "%1$s \"%3$s %4$s %5$s\" %6$s %7$s";
              };
            };
          };
        };
      };

      thelessone.caddy.vHost."map.theless.one".proxy = {
        inherit
          (config.services.minecraft-servers'.servers.smp.symlinks."config/bluemap/webserver.conf".value)
          port
          ;
      };

      # services.postgresql = {
      #   ensureDatabases = [ "smp-ledger" ];
      #   ensureUsers = [
      #     {
      #       name = "smp-ledger";
      #       ensureDBOwnership = true;
      #       # Don't know how to feel about this...
      #       ensureClauses.password = "SCRAM-SHA-256$4096:5v42qnWdS02ImuTiBnwtVw==$RRgNdaf05jbHaNmmeqdlt8QCS9lpxN+etnGl3SqB+zE=:3AbP2vlYrJxttAKNTYrYTpzuQXj4EEcmOktKtKfYMr4=";
      #     }
      #   ];
      # };
    };
}
