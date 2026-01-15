{ config, ... }:

let
  domain = "sabnzbd.theless.one";
in

{
  services.vopono.allowedTCPPorts = [ 8080 ];

  systemd.services.sabnzbd.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.sabnzbd = {
    enable = true;
    inherit (config.arr) group;
    settings.host_whitelist = "sabnzbd.theless.one";
  };

  config'.caddy.vHost.${domain} = {
    proxy.port = 8080;
    useVpn = true;
  };

  services.borgbackup.jobs.sabnzbd = {
    repo = "thelessone-borg@10.0.0.6:sabnzbd";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var/lib/sabnzbd";

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
