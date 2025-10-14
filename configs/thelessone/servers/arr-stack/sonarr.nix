{ config, ... }:

let
  domain = "https://sonarr.theless.one";
in

{
  services.vopono.allowedTCPPorts = [ config.services.sonarr.settings.server.port ];

  systemd.services.sonarr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.sonarr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.sonarr.settings.server) port; };
    useMtls = true;
  };

  config'.homepage.categories.Arr.services.Sonarr = {
    icon = "sonarr.svg";
    href = domain;
    siteMonitor = domain;
    description = "Series manager";
  };
}
