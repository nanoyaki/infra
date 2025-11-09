{ config, ... }:

let
  domain = "jellyseerr.theless.one";
in

{
  sops.secrets."restic/jellyseerr" = { };

  services.jellyseerr.enable = true;

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.jellyseerr) port; };
    useVpn = true;
  };

  config'.restic.backups.jellyseerr = {
    repository = "/mnt/raid/backups/jellyseerr";
    passwordFile = config.sops.secrets."restic/jellyseerr".path;

    basePath = "/var/lib/private/jellyseerr";

    timerConfig.OnCalendar = "daily";
  };
}
