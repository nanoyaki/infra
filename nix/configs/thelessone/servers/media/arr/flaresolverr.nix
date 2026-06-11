{
  flake.nixosModules.thelessone-flaresolverr =
    { lib, config, ... }:

    let
      inherit (config) prt;
    in

    {
      prt.flaresolverr = 8020;

      services.vopono.allowedTCPPorts = [ prt.flaresolverr ];

      systemd.services.flaresolverr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.flaresolverr = {
        enable = true;
        port = prt.flaresolverr;
      };
    };
}
