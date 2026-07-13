{
  flake.nixosModules.tubaki-host =
    { lib, ... }:

    {
      networking = {
        hostId = "3b14ec24";
        hostName = "tubaki";
        domain = "nanoyaki.space";
        fqdn = "mail.nanoyaki.space";
      };

      networking.interfaces.ens6 = {
        ipv6.addresses = lib.singleton {
          address = "2a01:239:43e:2c00::1";
          prefixLength = 64;
        };

        ipv4.addresses = lib.singleton {
          address = "31.70.93.127";
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
    };
}
