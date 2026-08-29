{
  flake.nixosModules.thelessone-minecraft-chloe =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (pkgs) formats;
      inherit (config.services.minecraft-servers.managementSystem.systemd-socket) stdinSocket;
      inherit (config) prt sec;
    in

    {
      prt.minecraft-server-chloe = 30056;
      prt.chloe-bluemap = 8036;

      systemd.services = lib.mkIf config.services.minecraft-servers'.servers.chloe.enable {
        minecraft-server-chloe.wantedBy = lib.mkForce [ "server-services.target" ];
      };
      services.minecraft-servers'.servers.chloe = {
        enable = true;

        extraStopPre = ''
          echo "say Server restart in 10 seconds" > ${stdinSocket.path "chloe"}
          sleep 10
        '';

        package = pkgs.neoforgeServers.neoforge-1_21_1;
        packageOverrides.jre_headless = pkgs.zulu25;
        appendJvmOpts = "-Dowo.handshake.disable=true";

        serverProperties.server-port = prt.minecraft-server-chloe;

        gamerules = {
          # SMP improvements
          playersSleepingPercentage = 33;
          # Disable movement checks due
          # to server upload speed limits
          disableElytraMovementCheck = true;
        };

        mods =
          pkgs.linkFarmFromDrvs
            (with config.services.minecraft-servers.modpacks.chloe; "modpack-chloe-mc${mcVersion}-${loader}")
            (
              config.services.minecraft-servers.modpacks.chloe.packages
              ++ [
                (pkgs.fetchurl {
                  # Community edition fixes some stuff apparently
                  url = "https://github.com/Metallurgists-of-Create/Create-TFMG-CE/releases/download/v1.2.4b/tfmg-1.21.1-1.2.4b-community.jar";
                  hash = "sha256-AaIKNdsBBq/80qqjGHKOG9HM7fU5eIvdwL5zh8EPdBo=";
                })
              ]
            );

        datapacks = null;

        symlinks = {
          "config/neovelocity-common.toml" = {
            format = formats.toml { };
            value = {
              forwarding.forwarding-secret = sec.proxy.path;
              forwarding.forwarding-secret-type = "FILE";

              compatibility.login-custom-packet-catchall = true;
            };
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
              port = prt.chloe-bluemap;

              log = {
                file = "logs/bluemap.log";
                append = true;
                format = "%1$s \"%3$s %4$s %5$s\" %6$s %7$s";
              };
            };
          };
        };
      };

      thelessone.caddy.vHost."chloe-map.theless.one" = {
        proxy.port = prt.chloe-bluemap;
        useTailnet = true;
      };

      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [ prt.minecraft-server-chloe ];
        allowedUDPPorts = [ prt.minecraft-server-chloe ];
      };

      services.minecraft-servers.modpacks.chloe = {
        mcVersion = "1.21.1";
        loader = "neoforge";
        mods = {
          addonslib = "1.21.1-1.14";
          ae2 = "19.2.17";
          ae2-import-export-card = "1.21.1-1.5.0";
          aerocopycats = {
            id = "wjpmYU1u";
            version = "1.1.0";
          };
          aeroengine = "1.3.0";
          almostunified = "1.21.1-1.4.2+neoforge";
          architectury-api = "13.0.11+neoforge";
          athena-ctm = "4.0.6";
          azimuth-api = "1.4.7";
          bellsandwhistles = "v0.4.7-1.21.1";
          better-library = "1.0.111";
          betterdays = "1.21.1-3.3.6.3-NEOFORGE";
          biomes-o-plenty = "21.1.0.14";
          bountiful-blocks = "1.21-0.9.9";
          cc-tweaked = "1.120.2";
          chipped = "4.0.2";
          cloth-config = "15.0.140+neoforge";
          comforts = "9.0.5+1.21.1";
          copycats = "3.0.8+mc.1.21.1-neoforge";
          create = "6.0.10+mc1.21.1";
          create-aeronautics = "1.3.1+mc1.21.1";
          create-aeronautics-lift-patch = "1.0.0";
          create-aeronautics-transmission-linkage = "0.2.7";
          create-aeroworks = "1.5.0+mc1.21.1";
          create-better-villagers = "1.3.2";
          create-big-cannons = "5.11.7";
          create-bits-n-bobs = "2.2.7";
          create-bits-n-dyes = "1.1.2";
          create-central-kitchen = "2.6.0";
          create-cobblestone = "1.4.12+neoforge-1.21.1-144";
          create-compatible-storage = "2.13.0-mc1.21.1-neoforge";
          create-connected = "1.3.2-mc1.21.1";
          create-deco = "2.1.3";
          create-design-n-decor = "2.2b";
          create-diesel-generators = "1.21.1-1.3.15";
          create-dragons-plus = "1.11.7b";
          create-dreams-and-desires = "2.3a-BETA";
          create-encased = "1.21.1-1.9.0-ht3";
          create-enchantment-industry = "2.5.3";
          create-factory = "0.7b-1.21.1";
          create-food = "2.7.1";
          create-garnished = "2.1.9.2+1.21.1-neoforged";
          create-goggles = "6.1.1";
          create-let-the-adventure-begin = "4.1.0";
          create-misc-and-things = "4.1.1";
          create-new-age = "1.2.0+mc1.21.1";
          create-ore-excavation = "1.21.1-1.6.8";
          create-propulsion-simulated = "1.1.5";
          create-railways-navigator = "1.21.1-beta-0.9.1-C6";
          create-sifting = "1.21.1-2.3.0";
          create-steam-n-rails = {
            id = "create-steam-n-rails-1.21.1";
            version = "0.3.0-beta.2+neoforge-mc1.21.1";
          };
          create-trading-floor = "3.0.16";
          create-transmission = {
            id = "create-transmission!";
            version = "1.2.2+neoforge-create6-1.21.1";
          };
          create-ultimate-factory = "1.9.0";
          createaddition = "neoforge-1.21.1-1.7.0";
          createnuclear = "1.3.2-beta.3";
          critters-and-companions = "2.7.0";
          curios = "9.5.1+1.21.1";
          delight-lib = "26.05.18-1.21-neoforge";
          delightful-creators = "1.2.1";
          dragonlib = "1.21.1-beta-3.0.28";
          dungeons-and-taverns = "v4.4.4+mod";
          enchanted-vertical-slabs = "2.3.2";
          escalated = "1.3.2";
          every-compat = "1.21-2.11.50";
          extended-ae = "1.21-2.2.35-neoforge";
          extendedae-plus = "1.6.1";
          farmers-delight = "1.21.1-1.3.3";
          farmers-knives = "1.21.1-4.2.0";
          forgified-fabric-api = "0.116.15+2.3.5+1.21.1";
          gabous-libs = "NeoForge-1.8.7";
          geckolib = "4.9.2";
          glitchcore = "2.1.0.2";
          glodium = "1.21-2.2-neoforge";
          gravestone-mod = "neoforge-1.21.1-1.0.40";
          guideme = "21.1.17";
          immersive-melodies = "0.7.1+1.21.1";
          interiors = "0.6.1";
          kotlin-for-forge = "5.12.0";
          lets-do-brewery-farmcharm-compat = "2.1.9";
          lets-do-farm-charm = "1.1.23";
          lets-do-furniture = "1.1.4";
          lets-do-herbalbrews = "1.1.3";
          lets-do-vinery = "1.5.3";
          lets-do-wildernature = "1.1.5";
          lithostitched = "1.8.0+beta4-neoforge-21.1";
          macaws-doors = "1.1.5";
          macaws-quark = "1.21.1-1.6.1";
          mafglib = "0.4.3+mc1.21.1";
          mechanicals-lib = "1.21.1-1.1.6";
          mega = "4.11.0";
          merequester = "1.21.1-1.4.3+neoforge";
          mod-primal = "1.1.6";
          moonlight = "1.21.1-3.5.0";
          more-delight = "26.05.20a-1.21-neoforge";
          nullscape = "1.2.14";
          numismatics = "1.0.20+neoforge-mc1.21.1";
          platform = "1.3.3";
          polymorph = "1.1.0+1.21.1";
          quark = "4.1-482";
          rechiseled = "1.2.5-neoforge-mc1.21";
          rechiseled-create = "1.1.1-neoforge-mc1.21";
          reconnectible-chains = "2.3.2-1.21.1-neoforge";
          resourceful-lib = "3.0.12";
          ribbits = "4.1.6";
          rpl = "2.1.2";
          sable = "2.0.5+mc1.21.1";
          serene-seasons = "10.1.0.3";
          serene-seasons-plus = "NeoForge-1.21.1-5.1.1";
          slice-and-dice = "4.3.3";
          sophisticated-backpacks = "1.21.1-3.25.78.2107";
          sophisticated-backpacks-create-integration = "1.21.1-0.1.8.134";
          sophisticated-core = "1.21.1-1.4.90.2299";
          stone-zone = "1.21-2.11.17-neoforge";
          storage-drawers-create-compat = "1.0.1+mod";
          storagedrawers = "1.21.1-13.11.4";
          strut-your-stuff = "1.3.0";
          supermartijn642s-config-lib = "1.1.8-neoforge-mc1.21";
          supermartijn642s-core-lib = "1.1.24-neoforge-mc1.21";
          supplementaries = "1.21.1-3.9.3";
          tectonic = "3.0.26-neoforge-21.1";
          terrablender = "4.1.0.8";
          terralith = "2.6.2";
          tide = "2.1.1";
          twigs = "1.21.1-3.1.2";
          underground-village = {
            id = "underground-village%2C-stoneholm";
            version = "2.0";
          };
          vanillabackport = "1.1.7.10";
          yacl = "3.8.2+1.21.1-neoforge";
          yungs-api = "1.21.1-NeoForge-5.1.8";
          zeta = "1.1-40";

          # Server stuff
          bluemap = "5.7-neoforge";
          neovelocity = "1.2.6";
          krypton-fnp = "0.2.28.1-1.21.1";
          ferrite-core = "7.0.3-neoforge";
          lithium = "mc1.21.1-0.15.4-neoforge";
          modernfix = "5.27.20+mc1.21.1";
          packet-fixer = "3.3.1";
          servercore = "1.5.19+1.21.1";
        };
      };
    };
}
