{
  flake.nixosModules.thelessone-flaresolverr =
    { lib, config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.flaresolverr.port ];

      systemd.services.flaresolverr.wantedBy = lib.mkForce [ "server-services.nix" ];
      services.flaresolverr = {
        enable = true;
        port = 8191;
      };
    };
}
