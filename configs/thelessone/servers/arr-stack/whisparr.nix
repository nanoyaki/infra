{ config, ... }:

let
  domain = "https://whisparr.theless.one";
in

{
  services.vopono.allowedTCPPorts = [ config.services.whisparr.settings.server.port ];

  systemd.services.whisparr.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.whisparr = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy.port = config.services.whisparr.settings.server.port;
    useMtls = true;
  };

  config'.homepage.categories.Arr.services.Whisparr = {
    icon = "whisparr.svg";
    href = domain;
    siteMonitor = domain;
    description = "Adult video manager";
  };
}
