{
  flake.nixosModules.thelessone-prowlarr =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.prowlarr = 8032;
      dmn.prowlarr = "prowlarr.theless.one";

      services.vopono.systemd.services.prowlarr = [ prt.prowlarr ];

      systemd.services.prowlarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.prowlarr = {
        enable = true;
        settings.server.port = prt.prowlarr;
        openFirewall = true;
      };

      thelessone.caddy.vHost.${dmn.prowlarr} = {
        proxy.host = config.services.vopono.voponoHost;
        proxy.port = prt.prowlarr;
        useTailnet = true;
      };

      thelessone.backups.prowlarr.paths = [ "/var/lib/private/prowlarr" ];
    };
}
