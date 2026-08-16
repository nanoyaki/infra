{
  flake.nixosModules.thelessone-tailscale =
    { config, ... }:

    {
      sec.tailscale = { };

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        authKeyFile = config.sec.tailscale.path;
        extraUpFlags = [
          "--login-server=https://headscale.nanoyaki.space"
          "--force-reauth"
          "--accept-dns=true"
        ];
      };

      networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };
}
