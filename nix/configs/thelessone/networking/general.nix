{
  flake.nixosModules.thelessone-networking = {
    networking = {
      hostId = "f617b7b6";
      hostName = "thelessone";
      domain = "theless.one";
      fqdn = "at01.theless.one";

      firewall.enable = true;
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
