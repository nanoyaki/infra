{
  flake.nixosModules.thelessone-tailscale =
    { config, ... }:

    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";
      };

      networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };
}
