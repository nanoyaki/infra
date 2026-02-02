{
  flake.nixosModules.thelessnas-networking = {
    networking = {
      hostId = "23d2908a";
      hostName = "thelessnas";

      defaultGateway = {
        address = "10.0.0.1";
        interface = "enp9s0";
      };
    };

    services.iperf3 = {
      enable = true;
      openFirewall = true;
    };
  };
}
