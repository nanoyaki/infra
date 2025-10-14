{ config, ... }:

let
  domain = "https://lidarr.theless.one";
in

{
  services.vopono.allowedTCPPorts = [ config.services.lidarr.settings.server.port ];

  systemd.services.lidarr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.lidarr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.lidarr.settings.server) port; };
    useMtls = true;
  };

  config'.homepage.categories.Arr.services.Lidarr = {
    icon = "lidarr.svg";
    href = domain;
    siteMonitor = domain;
    description = "Music manager";
  };
}
