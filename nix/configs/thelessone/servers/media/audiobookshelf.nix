{
  flake.nixosModules.thelessone-audiobookshelf =
    { lib, config, ... }:

    {
      services.audiobookshelf = {
        enable = true;
        port = 46551;
      };

      fileSystems."/var/lib/audiobookshelf" = {
        device = "/mnt/raid/audiobookshelf";
        depends = [ "/mnt/raid" ];
        options = [ "bind" ];
        fsType = "none";
      };

      systemd.services.audiobookshelf.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = "/mnt/raid/audiobookshelf";

      thelessone.caddy.vHost."audiobookshelf.theless.one" = {
        proxy = {
          inherit (config.services.audiobookshelf) port;
        };
        useTailnet = true;
      };

      thelessone.backups.audiobookshelf.paths = [ "/mnt/raid/audiobookshelf" ];
    };
}
