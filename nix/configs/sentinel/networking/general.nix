{
  flake.nixosModules.sentinel-networking = {
    networking = {
      hostId = "3077d2d8";
      hostName = "sentinel";
      domain = "theless.one";
      fqdn = "de01.theless.one";
    };

    services.iperf3 = {
      enable = true;
      openFirewall = true;
    };
  };
}
