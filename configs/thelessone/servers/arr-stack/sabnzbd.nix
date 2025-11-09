{ config, ... }:

let
  domain = "sabnzbd.theless.one";
in

{
  sops.secrets."restic/sabnzbd" = { };

  services.vopono.allowedTCPPorts = [ 8080 ];

  systemd.services.sabnzbd.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.sabnzbd = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy.port = 8080;
    useVpn = true;
  };

  config'.restic.backups.sabnzbd = {
    repository = "/mnt/raid/backups/sabnzbd";
    passwordFile = config.sops.secrets."restic/sabnzbd".path;

    basePath = "/var/lib/sabnzbd";

    timerConfig.OnCalendar = "daily";
  };
}
