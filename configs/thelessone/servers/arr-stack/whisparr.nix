{ config, ... }:

let
  domain = "whisparr.theless.one";
in

{
  sops.secrets."restic/whisparr" = { };

  services.vopono.allowedTCPPorts = [ config.services.whisparr.settings.server.port ];

  systemd.services.whisparr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.whisparr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy.port = config.services.whisparr.settings.server.port;
    useVpn = true;
  };

  config'.restic.backups.whisparr = {
    repository = "/mnt/raid/backups/whisparr";
    passwordFile = config.sops.secrets."restic/whisparr".path;

    basePath = "/var/lib/whisparr";

    timerConfig.OnCalendar = "daily";
  };
}
