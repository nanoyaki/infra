{ config, ... }:

let
  domain = "sonarr.theless.one";
in

{
  services.vopono.allowedTCPPorts = [ config.services.sonarr.settings.server.port ];

  systemd.services.sonarr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.sonarr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.sonarr.settings.server) port; };
    useVpn = true;
  };

  services.borgbackup.jobs.sonarr = {
    repo = "thelessone-borg@10.0.0.6:sonarr";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var/lib/sonarr";

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
