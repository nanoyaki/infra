{
  flake.nixosModules.thelessone-radarr =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.radarr = 8033;
      dmn.radarr = "radarr.theless.one";

      services.vopono.allowedTCPPorts = [ prt.radarr ];

      systemd.services.radarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.radarr = {
        enable = true;
        settings.server.port = prt.radarr;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost.${dmn.radarr} = {
        proxy.port = prt.radarr;
        useTailnet = true;
      };

      thelessone.backups.radarr.paths = [ "/var/lib/radarr" ];
    };
}
