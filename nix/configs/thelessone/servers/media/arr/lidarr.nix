{
  flake.nixosModules.thelessone-lidarr =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.lidarr = 8031;
      dmn.lidarr = "lidarr.theless.one";

      services.vopono.allowedTCPPorts = [ prt.lidarr ];

      systemd.services.lidarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.lidarr = {
        enable = true;
        settings.server.port = prt.lidarr;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost.${dmn.lidarr} = {
        proxy.port = prt.lidarr;
        useTailnet = true;
      };

      thelessone.backups.lidarr.paths = [ "/var/lib/lidarr" ];
    };
}
