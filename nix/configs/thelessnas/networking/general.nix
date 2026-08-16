{
  flake.nixosModules.thelessnas-networking = {
    networking = {
      hostId = "23d2908a";
      hostName = "thelessnas";

      defaultGateway = {
        address = "10.0.0.1";
        interface = "enp6s0";
      };

      defaultGateway6 = {
        address = "fe80::6b4:feff:fe15:19e5";
        interface = "enp6s0";
      };

      interfaces.enp6s0 = {
        ipv6.addresses = [
          {
            address = "fd1e:5501:7e00::3";
            prefixLength = 64;
          }
          {
            address = "2001:4bb8:1cf:ff47::1e5:5017:e003";
            prefixLength = 64;
          }
        ];

        ipv4.addresses = [
          {
            address = "10.0.0.6";
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
