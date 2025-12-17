{ config, ... }:

let
  cfg = config.services.actual;
in

{
  services.actual = {
    enable = true;
    openFirewall = true;
    settings.port = 7500;
  };

  config'.caddy.vHost."finances.theless.one" = {
    proxy = { inherit (cfg.settings) port; };
    useVpn = true;
  };

  services.borgbackup.jobs.actual = {
    repo = "thelessone-borg@10.0.0.6:actual";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var/lib/private/actual";

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
