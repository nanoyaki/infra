{
  flake.nixosModules.thelessone-minecraftModded =
    { pkgs, config, ... }:

    let
      inherit (pkgs) formats;
      inherit (config.services.minecraft-servers.managementSystem) tmux;
    in

    {
      services.minecraft-servers'.servers.modded = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_20_1;

        extraStopPre = ''
          tmux -S ${tmux.socketPath "modded"} send-keys "say Server restart in 10 seconds" Enter
          sleep 10
        '';

        serverProperties.server-port = 30055;

        gamerules = {
          # SMP improvements
          playersSleepingPercentage = 33;
          # Disable movement checks due
          # to server upload speed limits
          disableElytraMovementCheck = true;
        };

        mods =
          (with pkgs.minecraft.fabric.v1_20_1; [
            # libraries
            architectury-api.latest
            cloth-config.latest
            yacl.latest
            fabric-api.latest
            fabric-language-kotlin.latest
            balm.latest
            cicada.latest
            # modded
            cardinal-components-api.v5_2_3
            cristel-lib.v1_1_5
            cynosure.v0_1_15
            forge-config-api-port.v8_0_3Fabric
            fabric-api.v0_92_7
            fabric-language-kotlin."v1_13_7+kotlin_2_2_21"
            geckolib.v4_8_3
            guard-ribbits.v1_20_1-Fabric-1_0_4
            lithostitched.v1_4_111_20
            moonlight.v1_20-2_16_27
            owo-lib."v0_11_2+1_20"
            pneumono_core."v1_2_1+1_20+A"
            reborncore.v5_8_15
            resourceful-lib.v2_1_29
            resourceful-config.v2_1_3
            rpl.v2_1_1
            supermartijn642s-core-lib.v1_1_20mc
            supermartijn642s-config-lib.v1_1_8amc
            trinkets.v3_7_2
            yungs-api.v1_20-Fabric-4_0_6
            fzzy-config.v0_7_6
            fusion-connected-textures.v1_2_12mc

            # velocity
            fabricproxy-lite.latest

            # optimization
            vmp-fabric.latest
            lithium.latest
            krypton.latest
            c2me-fabric.latest
            ferrite-core.latest
            chunky.latest
            entityculling.latest
            faster-random.latest
            lithium.latest
            memoryleakfix.latest
            modernfix.latest

            # qol
            no-chat-reports.latest
            image2map.latest
            bluemap.latest
            bluemap-sign-markers.latest
            netherportalfix.latest
            rei.latest

            # admin
            player-roles.latest
            invview.latest

            # create
            create-fabric."v0_5_1-j-build_1631+mc"
            createaddition."fabric1_2_6"
            bellsandwhistles.v0_4_5-mc
            create-big-cannons.v5_8_2
            create-bluemap.v1_0_0build_32
            create-clockwork.v1_20_1-0_1_16
            create-enchantment-industry-fabric-legacy.v1_2_16
            createnuclear.v1_3_0
            create-ore-excavation.v1_20_1-1_5_4
            create-railways-navigator.v1_20_1-beta-0_8_4
            copycats."v2_2_0+mc_"
            interiors.v0_5_6mc
            create-new-age.v1_1_2
            create-steam-n-rails.v1_6_9mc
            create-structures."v0_1_1+mod"

            # modded
            ad-astra.v1_15_20
            ad-astra-giselle-addon.v6_19
            ad_extendra-continuation.v1_1_2
            applied-energistics-2-wireless-terminals.v15_2_1
            alloy-forgery."v2_1_2+1_20"
            almost-unified.v1_20_1-0_11_0
            ae2.v15_4_10
            bosses-of-mass-destruction.v1_7_5
            botarium.v2_3_4
            ct-overhaul-village.v3_3_6
            comforts.v6_4_0
            connectiblechains.v2_5_7
            dungeons-and-taverns."v3_0_3_f+mod"
            elytra-trims.v3_9_3
            enchanted-vertical-slabs.v2_2_1
            extended-cogwheels.v2_1_10_5_1_f
            fabric-seasons."v2_4_2-BETA+1_20"
            fabric-seasons-terralith-compat.v1_0
            lets-do-herbalbrews.v1_0_12
            macaws-doors.v1_1_5
            merequester.v1_20_1-1_1_4
            mythicmetals.v0_19_11
            mythicmetals-decorations.v0_6_4
            naturalist.v5_0pre3
            nullscape.v1_2_8
            planetsplus."BV1_7_5-MAINPACK-MOD"
            polymorph.v0_49_10
            polymorphic-energistics."fabric-0_1_1"
            quarry-reborn.v1_2_0
            rechiseled.v1_2_3mc
            ribbits.v3_0_5
            simply-swords.v1_56_0
            sound-physics-remastered."fabric1_5_1"
            spelunkery.v1_20_1-0_3_16
            spelunkery-no-easy-teleport.v1_0_0-rtp
            techreborn.v5_8_15
            tectonic.v3_0_17
            terralith.v2_5_4
            terralith-restoned.v1_3
            towns-and-towers.v1_12
            twigs.v3_1_0
            valkyrien-skies.v1_20_12_3_0-beta_5
            xaeros-minimap."fabric25_3_10"
            yigd.v2_0_16
          ])
          ++ (with pkgs.minecraft.fabric; [
            v1_20_1."shulker+".v1_0_7
            v1_20_1."sophisticated-backpacks-(unoffical-fabric-port)".v1_20_1-3_23_4_5_110
            v1_20_1."sophisticated-core-(unofficial-fabric-port)".v1_20_1-1_2_7_15_166
            v1_20_1."sophisticated-storage-(unofficial-fabric-port)".v1_20_1-1_3_5_9_136
            v1_20_1."sophisticated-storage-in-motion-(unofficial-fabric-port)".v1_20_1-0_10_5_1_37
          ]);

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

      thelessone.caddy.vHost."mod-map.theless.one".proxy = {
        inherit
          (config.services.minecraft-servers'.servers.modded.symlinks."config/bluemap/webserver.conf".value)
          port
          ;
      };
    };
}
