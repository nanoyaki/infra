{ pkgs, ... }:

let
  inherit (pkgs) formats;
in

{
  services.minecraft-servers'.servers.proxy = {
    enable = true;
    autoStart = true;
    package = pkgs.velocityServers.velocity;
    jvmOpts = "-Xms1G -Xmx1G";
    stopCommand = "end";

    symlinks."velocity.toml" = {
      format = formats.toml { };
      value = {
        config-version = "2.7";
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
          smp2 = "127.0.0.1:30053";

          try = [
            "smp"
            "lobby"
          ];
        };

        forced-hosts = {
          "theless.one" = [ "smp" ];
          "creative.theless.one" = [ "creative" ];
          "lobby.theless.one" = [ "lobby" ];
          "nik.theless.one" = [ "smp2" ];
        };

        query.enabled = false;
      };
    };

    files."forwarding.secret" = pkgs.writeText "forwarding.secret" "@FABRIC_PROXY_SECRET@";
  };
}
