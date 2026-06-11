{
  flake.nixosModules.thelessone-audiobookshelf =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.audiobookshelf = 8018;
      dmn.audiobookshelf = "audiobookshelf.theless.one";

      services.audiobookshelf = {
        enable = true;
        port = prt.audiobookshelf;
      };

      fileSystems."/var/lib/audiobookshelf" = {
        device = "/mnt/raid/audiobookshelf";
        depends = [ "/mnt/raid" ];
        options = [ "bind" ];
        fsType = "none";
      };

      systemd.services.audiobookshelf.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = "/mnt/raid/audiobookshelf";

      thelessone.caddy.vHost.${dmn.audiobookshelf} = {
        proxy.port = prt.audiobookshelf;
        useTailnet = true;
      };

      thelessone.backups.audiobookshelf.paths = [ "/mnt/raid/audiobookshelf" ];
    };
}
