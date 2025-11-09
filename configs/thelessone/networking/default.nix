{
  imports = [
    ./deployment.nix
    ./firewall.nix
    ./interface.nix
    ./wireguard.nix
  ];

  networking.useDHCP = true;
  networking.networkmanager.enable = false;
  networking.domain = "theless.one";

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
    "8.8.4.4"
  ];

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
}
