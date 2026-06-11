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
