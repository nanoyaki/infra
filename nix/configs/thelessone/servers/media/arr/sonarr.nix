{
  flake.nixosModules.thelessone-sonarr =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.sonarr = 8034;
      dmn.sonarr = "sonarr.theless.one";

      services.vopono.allowedTCPPorts = [ prt.sonarr ];

      systemd.services.sonarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.sonarr = {
        enable = true;
        settings.server.port = prt.sonarr;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost.${dmn.sonarr} = {
        proxy.port = prt.sonarr;
        useTailnet = true;
      };

      thelessone.backups.sonarr.paths = [ "/var/lib/sonarr" ];
    };
}
