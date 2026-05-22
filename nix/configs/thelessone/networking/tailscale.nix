{
  flake.nixosModules.thelessone-tailscale = _: {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };
  };
}
