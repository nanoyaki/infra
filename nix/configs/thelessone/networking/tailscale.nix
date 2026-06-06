{
  flake.nixosModules.thelessone-tailscale =
    { lib, config, ... }:

    let
      inherit (lib)
        mkOption
        types
        ;
    in

    {
      options.thelessone.tailscale.extraRecords = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };

      config = {
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "both";
        };

        networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
      };
    };
}
