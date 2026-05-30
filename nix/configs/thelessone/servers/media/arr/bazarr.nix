{
  flake.nixosModules.thelessone-bazarr =
    { lib, config, ... }:

    {
      systemd.services.bazarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.bazarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."bazarr.theless.one" = {
        proxy.port = config.services.bazarr.listenPort;
        useTailnet = true;
      };

      thelessone.backups.bazarr.paths = [ "/var/lib/bazarr" ];
    };
}
