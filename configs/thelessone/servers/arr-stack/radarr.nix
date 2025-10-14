{ config, ... }:
let
  domain = "https://radarr.theless.one";
in

{
  services.vopono.allowedTCPPorts = [ config.services.radarr.settings.server.port ];

  systemd.services.radarr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.radarr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.radarr.settings.server) port; };
    useMtls = true;
  };

  config'.homepage.categories.Arr.services.Radarr = {
    icon = "radarr.svg";
    href = domain;
    siteMonitor = domain;
    description = "Movie manager";
  };
}
