{ config, ... }:

let
  domain = "prowlarr.theless.one";
in

{
  services.vopono.systemd.services.prowlarr = [ config.services.prowlarr.settings.server.port ];

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  config'.caddy.vHost.${domain} = {
    proxy = {
      inherit (config.services.prowlarr.settings.server) port;
      host = config.services.vopono.voponoHost;
    };
    useVpn = true;
  };

  services.borgbackup.jobs.prowlarr = {
    repo = "thelessone-borg@10.0.0.6:prowlarr";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var/lib/private/prowlarr";

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
