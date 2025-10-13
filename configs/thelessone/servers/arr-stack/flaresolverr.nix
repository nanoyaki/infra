{ pkgs, config, ... }:

{
  services.vopono.allowedTCPPorts = [ config.services.flaresolverr.port ];

  services.flaresolverr = {
    enable = true;
    port = 8191;
    package = pkgs.nur.repos.xddxdd.flaresolverr-21hsmw;
  };
}
