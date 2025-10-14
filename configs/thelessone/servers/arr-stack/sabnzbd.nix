{ config, ... }:

let
  domain = "https://sabnzbd.theless.one";
in

{
  services.vopono.allowedTCPPorts = [ 8080 ];

  systemd.services.sabnzbd.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.sabnzbd = {
    enable = true;
    inherit (config.arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy.port = 8080;
    useMtls = true;
  };

  config'.homepage.categories.Arr.services.Sabnzbd = {
    icon = "sabnzbd.svg";
    href = domain;
    siteMonitor = domain;
    description = "Usenet binary downloader";
  };
}
