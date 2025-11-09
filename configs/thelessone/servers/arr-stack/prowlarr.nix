{ config, ... }:

let
  domain = "prowlarr.theless.one";
in

{
  sops.secrets."restic/prowlarr" = { };

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

  config'.restic.backups.prowlarr = {
    repository = "/mnt/raid/backups/prowlarr";
    passwordFile = config.sops.secrets."restic/prowlarr".path;

    basePath = "/var/lib/prowlarr";

    timerConfig.OnCalendar = "daily";
  };
}
