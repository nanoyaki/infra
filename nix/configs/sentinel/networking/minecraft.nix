{ inputs, ... }:

{
  flake.nixosModules.sentinel-minecraft =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib) mkForce;
      inherit (config) prt plh tpl;
    in

    {
      imports = [
        inputs.nix-minecraft.nixosModules.minecraft-servers
      ];

      prt.minecraft = mkForce 25565;

      sec.proxy = { };
      tpl."minecraft.env".file = pkgs.writeEnv "minecraft.env.tpl" {
        PROXY_SECRET = plh.proxy;
      };

      services.minecraft-servers = {
        enable = true;
        eula = true;
        openFirewall = true;
        dataDir = "/var/lib/minecraft";
        environmentFile = tpl."minecraft.env".path;

        servers.proxy = {
          enable = true;
          autoStart = true;
          package = pkgs.velocityServers.velocity.override { jre_headless = pkgs.zulu25; };
          jvmOpts = lib.concatStringsSep " " [
            "-Xms512M"
            "-Xmx512M"
            "-Dvelocity.max-plugin-message-payload-size=1624985"
            "-Dvelocity.max-known-packs=196"
          ];
          stopCommand = "end";

          managementSystem.tmux.enable = false;
          managementSystem.systemd-socket.enable = true;

          # files, so it doesn't kill itself when migrating
          files."velocity.toml" = {
            format = pkgs.formats.toml { };
            value = {
              config-version = "2.9";
              bind = "0.0.0.0:${toString prt.minecraft}";
              motd =
                "<#dce0e8>T</#dce0e8><#8caaee>h</#8caaee><#dce0e8>e</#dce0e8>"
                + "<#8caaee>l</#8caaee><#dce0e8>e</#dce0e8><#8caaee>s</#8caaee><#dce0e8>s</#dce0e8>"
                + "<#8caaee>.</#8caaee><#dce0e8>o</#dce0e8><#8caaee>n</#8caaee><#dce0e8>e</#dce0e8>"
                + " <#8caaee>❄</#8caaee>";
              show-max-players = 50;
              online-mode = true;
              force-key-authentication = true;
              player-info-forwarding-mode = "MODERN";
              forwarding-secret-file = "forwarding.secret";
              kick-existing-players = true;
              sample-players-in-ping = true;
              enable-player-address-logging = false;

              ping-passthrough = {
                version = true;
                players = true;
                description = true;
                favicon = true;
                modinfo = true;
              };

              forced-hosts = {
                "theless.one" = [ "smp" ];
                "smp.theless.one" = [ "smp" ];
                "chloe.theless.one" = [ "chloe" ];
              };

              servers = {
                smp = "100.64.0.2:${toString 30050}";
                chloe = "100.64.0.2:${toString 30056}";
                try = [
                  "smp"
                  "chloe"
                ];
              };

              query.enabled = false;
              advanced = {
                tcp-fast-open = true;
                connection-timeout = 60000;
                read-timeout = 60000;
              };
            };
          };

          files."forwarding.secret" = pkgs.writeText "forwarding.secret" "@PROXY_SECRET@";
          files."server-icon.png" = "${pkgs.thelessone-minecraft-logomark}/icon.png";
        };
      };

      networking.firewall.allowedTCPPorts = [ prt.minecraft ];
      networking.firewall.allowedUDPPorts = [ prt.minecraft ];
    };
}
