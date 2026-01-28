{
  flake.nixosModules.thelessone-networking = {
    networking = {
      firewall = true;
      nftables.enable = true;
      networkmanager.enable = true;

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
