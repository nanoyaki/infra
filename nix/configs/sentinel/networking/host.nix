{
  flake.nixosModules.sentinel-host =
    { lib, ... }:

    {
      networking = {
        hostId = "3077d2d8";
        hostName = "sentinel";
        domain = "nanoyaki.space";
        fqdn = "nanoyaki.space";
      };

      networking.interfaces.ens6 = {
        ipv6.addresses = lib.singleton {
          address = "2a01:239:454:9300::1";
          prefixLength = 64;
        };

        ipv4.addresses = lib.singleton {
          address = "85.215.152.236";
          prefixLength = 32;
        };
      };

      networking.defaultGateway = {
        address = "85.215.152.1";
        interface = "ens6";
      };

      networking.defaultGateway6 = {
        address = "fe80::1";
        interface = "ens6";
      };

      services.iperf3 = {
        enable = true;
        openFirewall = true;
      };
    };
}
