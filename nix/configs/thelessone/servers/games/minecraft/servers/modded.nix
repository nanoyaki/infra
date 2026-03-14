{
  flake.nixosModules.thelessone-minecraftModded =
    {
      pkgs,
      config,
      ...
    }:

    let
      inherit (pkgs) formats;
      inherit (config.services.minecraft-servers.managementSystem.systemd-socket) stdinSocket;
    in

    {
      services.minecraft-servers'.servers.modded-test = {
        enable = true;

        extraStopPre = ''
          echo "say Server restart in 10 seconds" > ${stdinSocket.path "modded-test"}
          sleep 10
        '';

        package = pkgs.neoforgeServers.neoforge-1_21_1-21_1_219;
        packageOverrides.jre_headless = pkgs.zulu21;
        appendJvmOpts = "-Dowo.handshake.disable=true";

        serverProperties.server-port = 30055;
        serverProperties.online-mode = false;

        gamerules = {
          # SMP improvements
          playersSleepingPercentage = 33;
          # Disable movement checks due
          # to server upload speed limits
          disableElytraMovementCheck = true;
        };

        mods =
          (map (pkg: pkg.latest) (
            with pkgs.minecraft.neoforge.v1_21_1;
            [
              # libs
              addonslib
              architectury-api
              balm
              cristel-lib
              curios
              fzzy-config
              gabous-libs
              geckolib
              glitchcore
              gravestone-mod
              lithostitched
              moonlight
              puzzles-lib
              potentials
              rpl
              supermartijn642s-config-lib
              supermartijn642s-core-lib
              txnilib
              yacl
              yungs-api
              zeta
              owo-lib
              kotlin-for-forge
              badpackets
              patchouli
              titanium
              mechanicals-lib
              athena-ctm
              dragonlib
              glodium
              forgified-fabric-api

              # general
              alloy-smelter
              almost-unified
              betterdays
              ct-overhaul-village
              cloth-config
              comforts
              dungeons-and-taverns
              enchanted-vertical-slabs
              every-compat
              leaves-be-gone
              lets-do-herbalbrews
              modern-industrialization
              nullscape
              polymorph
              quark
              rechiseled
              reconnectible-chains
              ribbits
              serene-seasons
              serene-seasons-plus
              simply-swords
              sound-physics-remastered
              stone-zone
              towns-and-towers
              xaeros-minimap
              xaeros-world-map
              jade
              jade-addons-forge
              storagedrawers
              industrial-foregoing
              oritech
              camerapture
              immersive-ores
              carry-on
              bountiful-blocks
              modular-routers

              # farmer's delight
              farmers-delight
              farmers-knives

              # sophisticated
              sophisticated-backpacks
              sophisticated-storage
              sophisticated-core
              sophisticated-storage-in-motion
              sophisticated-storage-create-integration
              sophisticated-backpacks-create-integration

              # stellaris
              stellaris
              tfmg-stellaris-compat

              # world gen
              tectonic
              terralith-restoned
              terralith

              # emi
              emi
              emi-ores
              advanced-loot-info

              # refined storage
              refined-storage
              refined-types
              refined-storage-quartz-arsenal
              refined-storage-mekanism-integration
              refined-storage-emi-integration

              # applied energistics
              ae2
              applied-energistics-2-wireless-terminals
              guideme
              merequester
              rechiseled-ae2
              mega
              ae2-import-export-card
              extended-ae
              extendedae-plus

              # mekanism
              mekanism
              mekanism-tools
              # mekanism-tfmg-compat
              mekanism-generators
              mekanism-additions
              applied-mekanistics

              # performance and server stuff
              entityculling
              ferrite-core
              immediatelyfast
              modernfix
              netherportalfix
              no-chat-reports
              noisiumforked
              redirected
              saturn
              proxy-compatible-forge
              chunky
              bluemap
              fastevent
              c2me-neoforge
              smooth-boot
              packet-fixer

              # cc tweaked
              cc-tweaked
              advancedperipherals

              # create
              create
              createaddition
              bellsandwhistles
              create-big-cannons
              create-deco
              create-diesel-generators
              create-goggles
              create-let-the-adventure-begin
              createnuclear
              create-ore-excavation
              create-railways-navigator
              slice-and-dice
              create-central-kitchen
              create-connected
              copycats
              create-dragons-plus
              create-dreams-and-desires
              create-drill-drain
              create-enchantment-industry
              interiors
              create-new-age
              create-polymer
              create-threaded-trains
              create-stellaris
              create-design-n-decor
              rechiseled-create
              create-steam-n-rails-1
              create-fd-dough
              create-confectionery
              create-factory
              storage-drawers-create-compat
              create-stock-bridge
              create-bits-n-bobs
              create-cobblestone
              create-ultimate-factory
              create-sifting
              create-jetpack
              cccbridge
              delightful-creators
              create-trading-floor
              create-misc-and-things

              # macaws
              macaws-bridges
              macaws-doors
              macaws-fences-and-walls
              macaws-furniture
              macaws-holidays
              macaws-lights-and-lamps
              macaws-paintings
              macaws-paths-and-pavings
              macaws-roofs
              macaws-stairs
              macaws-trapdoors
              macaws-windows
              macaws-quark
            ]
          ))
          ++ (map (pkg: pkgs.minecraft.neoforge.v1_21_1.${pkg}.latest) [
            "create-track-map-(unofficial-fork)"
            "put-a-plug-in-it!"
          ])
          # locked packages
          ++ (with pkgs.minecraft.neoforge.v1_21_1; [
            create-tfmg.v1_1_1
          ]);

        datapacks = null;

        files."config/proxy-compatible-forge.toml" = {
          format = formats.toml { };
          value = {
            forwarding = {
              enabled = true;
              secret = "@PROXY_SECRET@";
              approvedProxyHosts = [
                "::1"
                "127.0.0.1"
                "localhost"
              ];
            };

            crossStitch.enabled = true;
            advanced.modernForwardingVersion = 4;
          };
        };

        symlinks = {
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
              port = 8101;

              log = {
                file = "logs/bluemap.log";
                append = true;
                format = "%1$s \"%3$s %4$s %5$s\" %6$s %7$s";
              };
            };
          };
        };
      };

      thelessone.caddy.vHost."modded.theless.one".proxy = {
        inherit
          (config.services.minecraft-servers'.servers.modded-test.symlinks."config/bluemap/webserver.conf".value
          )
          port
          ;
      };
      thelessone.caddy.vHost."trains-modded.theless.one".proxy.port = 3876;
    };
}
