{ config, ... }:

let
  domain = "sonarr.theless.one";
in

{
  sops.secrets."restic/sonarr" = { };

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

  config'.restic.backups.sonarr = {
    repository = "/mnt/raid/backups/sonarr";
    passwordFile = config.sops.secrets."restic/sonarr".path;

    basePath = "/var/lib/sonarr";

    timerConfig.OnCalendar = "daily";
  };
}
