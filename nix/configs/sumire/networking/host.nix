{
  flake.nixosModules.sumire-host =
    { lib, ... }:

    {
      networking = {
        hostId = "b4bd4c12";
        hostName = "sumire";
        domain = "nanoyaki.space";
        fqdn = "matrix.nanoyaki.space";
      };

      networking.interfaces.ens18 = {
        ipv6.addresses = lib.singleton {
          address = "2a0f:6284:4300:101::110d";
          prefixLength = 64;
        };

        ipv4.addresses = lib.singleton {
          address = "5.175.180.4";
          prefixLength = 32;
        };
      };

      networking.defaultGateway = {
        address = "5.175.180.1";
        interface = "ens18";
      };

      networking.defaultGateway6 = {
        address = "fe80::1";
        interface = "ens18";
      };
    };
}
