{ config, ... }:

let
  domain = "https://jellyseerr.theless.one";
in

{

  services.jellyseerr.enable = true;

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.jellyseerr) port; };
    useMtls = true;
  };

  config'.homepage.categories.Arr.services.Jellyseerr = {
    icon = "jellyseerr.svg";
    href = domain;
    siteMonitor = domain;
    description = "Media request manager";
  };
}
