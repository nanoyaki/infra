{
  flake.nixosModules.thelessone-bazarr =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.bazarr = 8030;
      dmn.bazarr = "bazarr.theless.one";

      systemd.services.bazarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.bazarr = {
        enable = true;
        listenPort = prt.bazarr;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost.${dmn.bazarr} = {
        proxy.port = prt.bazarr;
        useTailnet = true;
      };

      thelessone.backups.bazarr.paths = [ "/var/lib/bazarr" ];
    };
}
