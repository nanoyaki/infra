{ pkgs, config, ... }:

let
  inherit (pkgs) formats;
in

{
  services.minecraft-servers'.servers.smp = {
    enable = true;
    package = pkgs.fabricServers.fabric-1_21_8;

    serverProperties = {
      server-port = 30050;

      # Joshs-more-foods
      require-resource-pack = true;
      resource-pack-prompt = ''
        The server requires this resource pack for the datapack joshs more foods.
        Using it does not mean you won't be able to use your own on top of it.
      '';
      resource-pack = "https://cdn.modrinth.com/data/3BlwZj8w/versions/bybBGRCd/joshs-more-foods_5.5.1_resource_pack.zip";
      resource-pack-sha1 = "0df9086d7918e03aed27fd4c2621177d7b81b31e";
    };

    gamerules = {
      locatorBar = false;
      disableElytraMovementCheck = true;
      disablePlayerMovementCheck = true;
      playersSleepingPercentage = 33;
    };

    datapacks = map (datapack: datapack.latest) (
      with pkgs.minecraft.datapack.v1_21_8;
      [
        dungeons-and-taverns
        joshs-more-foods
        mini-blocks-datapack
      ]
    );

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

        bluemap
        bluemap-sign-markers
        discord-mc-chat
        distanthorizons
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

  config'.caddy.vHost."map.theless.one".proxy = {
    inherit (config.services.minecraft-servers'.smp.symlinks."config/bluemap/webserver.conf".value)
      port
      ;
  };
}
