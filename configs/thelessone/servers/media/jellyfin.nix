{ pkgs, config, ... }:

let
  domain = "jellyfin.theless.one";
in

{
  services.jellyfin = {
    enable = true;
    package = pkgs.jellyfin.override {
      jellyfin-web = pkgs.jellyfin-web-with-plugins;
    };
    inherit (config.arr) group;
  };
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";

  config'.caddy.vHost.${domain} = {
    proxy.port = 8096;
    useVpn = true;
  };

  users.users.${config.services.jellyfin.user}.extraGroups = [
    "video"
    "render"
  ];

  sops.secrets."restic/jellyfin" = { };

  config'.restic.backups.jellyfin = {
    repository = "/mnt/raid/backups/jellyfin";
    passwordFile = config.sops.secrets."restic/jellyfin".path;

    basePath = "/var/lib/jellyfin";
    exclude = [
      "metadata/library"
      "data/subtitles"
    ];

    timerConfig.OnCalendar = "daily";
  };
}
