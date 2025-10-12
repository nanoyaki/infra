{ config, ... }:

let
  domain = "https://prowlarr.theless.one";
in

{
  services.vopono.systemd.services.prowlarr = [ config.services.prowlarr.settings.server.port ];

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  config'.caddy.vHost.${domain}.proxy = {
    inherit (config.services.prowlarr.settings.server) port;
    inherit (config.services.vopono) host;
  };

  config'.homepage.categories.Arr.services.Prowlarr = {
    icon = "prowlarr.svg";
    href = domain;
    siteMonitor = domain;
    description = "Indexer manager";
  };
}
