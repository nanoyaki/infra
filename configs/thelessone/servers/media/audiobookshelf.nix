{ config, ... }:

let
  domain = "audiobookshelf.theless.one";
in

{
  services.audiobookshelf = {
    enable = true;
    port = 46551;
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

  services.borgbackup.jobs.audiobookshelf = {
    repo = "thelessone-borg@10.0.0.6:audiobookshelf";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/mnt/raid/audiobookshelf";

    encryption.mode = "none";
    compression = "zstd";

    startAt = "daily";
    persistentTimer = true;
    prune.keep = {
      within = "1d";
      daily = 14;
      weekly = 12;
      monthly = -1;
    };
  };
}
