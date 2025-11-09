{ config, ... }:
let
  domain = "radarr.theless.one";
in

{
  sops.secrets."restic/radarr" = { };

  services.vopono.allowedTCPPorts = [ config.services.radarr.settings.server.port ];

  systemd.services.radarr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.radarr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.radarr.settings.server) port; };
    useVpn = true;
  };

  config'.restic.backups.radarr = {
    repository = "/mnt/raid/backups/radarr";
    passwordFile = config.sops.secrets."restic/radarr".path;

    basePath = "/var/lib/radarr";

    timerConfig.OnCalendar = "daily";
  };
}
