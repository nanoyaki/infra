{ config, ... }:

{
  services.vopono.allowedTCPPorts = [ config.services.flaresolverr.port ];

  services.flaresolverr = {
    enable = true;
    port = 8191;
  };
}
