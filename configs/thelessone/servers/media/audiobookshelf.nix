{ config, ... }:

let
  domain = "audiobookshelf.theless.one";
in

{
  services.audiobookshelf = {
    enable = true;
    port = 46551;
  };

  sops.secrets."restic/audiobookshelf" = { };

  config'.restic.backups.audiobookshelf = {
    repository = "/mnt/raid/backups/audiobookshelf";
    passwordFile = config.sops.secrets."restic/audiobookshelf".path;

    basePath = "/mnt/raid/audiobookshelf";

    timerConfig.OnCalendar = "daily";
  };

  fileSystems."/var/lib/audiobookshelf" = {
    device = "/mnt/raid/audiobookshelf";
    depends = [ "/mnt/raid" ];
    options = [ "bind" ];
  };

  systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = "/mnt/raid/audiobookshelf";

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.audiobookshelf) port; };
    useVpn = true;
  };
}
