{
  flake.nixosModules.thelessone-networking =
    _:

    {
      dmn.self = "theless.one";
      dmn.self-fqdn = "at01.theless.one";

      networking = {
        hostId = "f617b7b6";
        hostName = "thelessone";
        domain = "theless.one";
        fqdn = "at01.theless.one";

        networkmanager.enable = false;
        useDHCP = false;

        defaultGateway = {
          address = "10.0.0.1";
          interface = "enp9s0";
        };

        defaultGateway6 = {
          address = "fe80::6b4:feff:fe15:19e5";
          interface = "enp9s0";
        };

        interfaces.enp9s0 = {
          ipv6.addresses = [
            {
              address = "fd1e:5501:7e00::2";
              prefixLength = 64;
            }
            {
              address = "2001:4bb8:1cf:ff47::1e5:5017:e002";
              prefixLength = 64;
            }
          ];

          ipv6.routes = [
            {
              address = "fd1e:5501:7e00::";
              prefixLength = 64;
              via = "fe80::6b4:feff:fe15:19e5";
            }
            {
              address = "2001:4bb8:1cf:ff47::";
              prefixLength = 64;
              via = "fe80::6b4:feff:fe15:19e5";
            }
          ];

          ipv4.addresses = [
            {
              address = "10.0.0.5";
              prefixLength = 24;
            }
          ];

          ipv4.routes = [
            {
              address = "10.0.0.0";
              prefixLength = 24;
            }
          ];
        };
      };

      services.iperf3 = {
        enable = true;
        openFirewall = true;
      };
    };
}
