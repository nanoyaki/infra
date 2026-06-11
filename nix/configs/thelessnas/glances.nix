{
  flake.nixosModules.thelessnas-glances =
    { config, ... }:

    let
      inherit (config) prt;
    in

    {
      prt.glances = 8000;

      services.glances.enable = true;
      services.glances.port = prt.glances;

      networking.firewall.interfaces.enp6s0.allowedTCPPorts = [ prt.glances ];
    };
}
