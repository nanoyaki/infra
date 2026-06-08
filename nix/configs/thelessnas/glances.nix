{
  flake.nixosModules.thelessnas-glances =
    { config, ... }:

    {
      services.glances.enable = true;
      networking.firewall.interfaces.enp6s0.allowedTCPPorts = [ config.services.glances.port ];
    };
}
