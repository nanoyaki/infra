{
  flake.nixosModules.thelessone-immich =
    { lib, config, ... }:

    {
      systemd.services.immich-server.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.immich-machine-learning.wantedBy = lib.mkForce [ "server-services.target" ];
      services.immich = {
        enable = true;
        accelerationDevices = [ "/dev/dri/renderD128" ];
      };

      users.users.${config.services.immich.user}.extraGroups = [
        "video"
        "render"
      ];

      systemd.services.immich-public-proxy.wantedBy = lib.mkForce [ "server-services.target" ];
      services.immich-public-proxy = {
        enable = true;
        immichUrl = "http://localhost:2283";
        port = 19220;
        settings.allowDownloadAll = 1;
      };

      thelessone.caddy.vHost."images.theless.one".proxy = {
        inherit (config.services.immich-public-proxy) port;
      };

      thelessone.caddy.vHost."immich.theless.one" = {
        proxy = { inherit (config.services.immich) port; };
        useTailnet = true;
      };

      thelessone.backups.immich.paths = [ "/var/lib/immich" ];
    };
}
