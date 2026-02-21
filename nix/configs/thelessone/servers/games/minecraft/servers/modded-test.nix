{
  flake.nixosModules.thelessone-minecraftModded =
    {
      pkgs,
      config,
      ...
    }:

    let
      inherit (pkgs) formats;
    in

    {
      services.minecraft-servers'.servers.modded-test = {
        enable = true;
        managementSystem = {
          tmux.enable = false;
          systemd-socket.enable = true;
        };

        package = pkgs.neoforgeServers.neoforge-1_21_1-21_1_219;
        packageOverrides.jre_headless = pkgs.zulu21;
        appendJvmOpts = "-Dowo.handshake.disable=true";

        serverProperties.server-port = 25568;

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
              cristel-lib
              curios
              fzzy-config
              gabous-libs
              geckolib
              glitchcore
              gravestone-mod
              kotlin-for-forge
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

              # general
              accessories
              accessories-compat-layer
              alloy-smelter
              almost-unified
              betterdays
              ct-overhaul-village
              cloth-config
              comforts
              dungeons-and-taverns
              enchanted-vertical-slabs
              every-compat
              lets-do-herbalbrews
              modern-industrialization
              nullscape
              owo-lib
              polymorph
              quark
              rechiseled
              reconnectible-chains
              rei
              ribbits
              serene-seasons
              serene-seasons-plus
              simply-swords
              sound-physics-remastered
              stone-zone
              towns-and-towers
              xaeros-minimap
              xaeros-world-map

              # stellaris
              stellaris
              tfmg-stellaris-compat

              # world gen
              tectonic
              terralith-restoned
              terralith

              # sophisticated
              sophisticated-backpacks
              sophisticated-core
              sophisticated-storage
              sophisticated-storage-in-motion

              # refined storage
              refined-storage
              refined-types
              refined-storage-rei-integration
              refined-storage-quartz-arsenal
              refined-storage-mekanism-integration

              # applied energistics
              ae2
              applied-energistics-2-wireless-terminals
              guideme
              merequester
              rechiseled-ae2

              # mekanism
              mekanism
              mekanism-tools
              mekanism-tfmg-compat
              mekanism-generators
              mekanism-additions

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
              create-tfmg
              create-threaded-trains
              create-stellaris
              create-design-n-decor
              rechiseled-create
              sophisticated-backpacks-create-integration
              sophisticated-storage-create-integration
              create-steam-n-rails-1

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
            ]
          ))
          ++ (with pkgs.minecraft.neoforge.v1_21_1; [
            create-tfmg.v1_1_1
            (pkgs.fetchurl {
              url = "https://files.theless.one/shared-public-download/spelunkery-1.21.1-BETA-26.2.16-neoforge.jar";
              hash = "sha256-UG/DpPXa2AyfduXPIfgCYJUDg6UHcCDGLaGB0X1BXec=";
            })
          ])
          ++ [
            pkgs.minecraft.neoforge.v1_21_1."create-track-map-(unofficial-fork)".latest
          ];

        datapacks = null;

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
              port = 8102;

              log = {
                file = "logs/bluemap.log";
                append = true;
                format = "%1$s \"%3$s %4$s %5$s\" %6$s %7$s";
              };
            };
          };
        };
      };

      thelessone.caddy.vHost."mod-map-test.theless.one".proxy = {
        inherit
          (config.services.minecraft-servers'.servers.modded-test.symlinks."config/bluemap/webserver.conf".value
          )
          port
          ;
      };
    };
}
