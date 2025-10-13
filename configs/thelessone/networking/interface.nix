{
  networking = {
    useDHCP = true;
    interfaces.enp6s0.useDHCP = true;

    defaultGateway = {
      address = "10.0.0.1";
      interface = "enp6s0";
    };
  };
}
