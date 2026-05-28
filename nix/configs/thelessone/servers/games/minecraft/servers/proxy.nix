{
  flake.nixosModules.thelessone-minecraftProxy =
    { lib, pkgs, ... }:

    {
      systemd.services.minecraft-server-proxy.wantedBy = lib.mkForce [ "server-services.target" ];
      services.minecraft-servers'.servers.proxy = {
        enable = true;
        autoStart = true;
        package = pkgs.velocityServers.velocity;
        jvmOpts = "-Xms1G -Xmx1G";
        stopCommand = "end";
        useDefaults = false;

        managementSystem = {
          tmux.enable = false;
          systemd-socket.enable = true;
        };

        symlinks."velocity.toml" = {
          format = pkgs.formats.toml { };
          value = {
            config-version = "2.8";
            bind = "0.0.0.0:25565";
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
            ping-passthrough = "DISABLED";
            sample-players-in-ping = true;

            servers = {
              smp = "127.0.0.1:30050";
              creative = "127.0.0.1:30051";
              lobby = "127.0.0.1:30052";
              flat = "127.0.0.1:30054";
              modded = "127.0.0.1:30055";

              try = [
                "smp"
                "lobby"
              ];
            };

            forced-hosts = {
              "theless.one" = [ "smp" ];
              "creative.theless.one" = [ "creative" ];
              "lobby.theless.one" = [ "lobby" ];
              "flat.theless.one" = [ "flat" ];
              "modded.theless.one" = [ "modded" ];
            };

            query.enabled = false;
          };
        };

        files."forwarding.secret" = pkgs.writeText "forwarding.secret" "@PROXY_SECRET@";
        files."server-icon.png" = "${pkgs.thelessone-minecraft-logomark}/icon.png";
      };
    };
}
