{
  flake.nixosModules.sentinel-host =
    { config, ... }:

    let
      inherit (config) dmn;
    in

    {
      dmn.self = "theless.one";
      dmn.self-fqdn = "de01.theless.one";

      networking = {
        hostId = "3077d2d8";
        hostName = "sentinel";
        domain = "theless.one";
        fqdn = dmn.self-fqdn;
      };

      services.iperf3 = {
        enable = true;
        openFirewall = true;
      };
    };
}
