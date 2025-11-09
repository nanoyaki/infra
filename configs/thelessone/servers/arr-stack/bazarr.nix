{ config, ... }:

let
  inherit (config) arr;

  domain = "bazarr.theless.one";
in

{
  sops.secrets."restic/bazarr" = { };

  services.bazarr = {
    enable = true;
    inherit (arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy.port = config.services.bazarr.listenPort;
    useVpn = true;
  };

  config'.restic.backups.bazarr = {
    repository = "/mnt/raid/backups/bazarr";
    passwordFile = config.sops.secrets."restic/bazarr".path;

    basePath = "/var/lib/bazarr";

    timerConfig.OnCalendar = "daily";
  };
}
