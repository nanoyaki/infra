{ config, ... }:

let
  domain = "lidarr.theless.one";
in

{
  sops.secrets."restic/lidarr" = { };

  services.vopono.allowedTCPPorts = [ config.services.lidarr.settings.server.port ];

  systemd.services.lidarr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.lidarr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.lidarr.settings.server) port; };
    useVpn = true;
  };

  config'.restic.backups.lidarr = {
    repository = "/mnt/raid/backups/lidarr";
    passwordFile = config.sops.secrets."restic/lidarr".path;

    basePath = "/var/lib/lidarr";

    timerConfig.OnCalendar = "daily";
  };
}
