{
  flake.nixosModules.thelessone-immich =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.immich = 8006;
      prt.immich-public-proxy = 8007;
      dmn.immich = "immich.theless.one";
      dmn.immich-public-proxy = "images.theless.one";

      systemd.services.immich-server.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.immich-machine-learning.wantedBy = lib.mkForce [ "server-services.target" ];
      services.immich = {
        enable = true;
        port = prt.immich;
        accelerationDevices = [ "/dev/dri/renderD128" ];
      };

      users.users.${config.services.immich.user}.extraGroups = [
        "video"
        "render"
      ];

      systemd.services.immich-public-proxy.wantedBy = lib.mkForce [ "server-services.target" ];
      services.immich-public-proxy = {
        enable = true;
        immichUrl = "http://localhost:${toString prt.immich}";
        port = prt.immich-public-proxy;
        settings.allowDownloadAll = 1;
      };

      thelessone.caddy.vHost.${dmn.immich-public-proxy}.proxy.port = prt.immich-public-proxy;
      thelessone.caddy.vHost.${dmn.immich} = {
        proxy.port = prt.immich;
        useTailnet = true;
      };

      thelessone.backups.immich.paths = [ "/var/lib/immich" ];
    };
}
