{
  networking = {
    useDHCP = true;
    interfaces.enp5s0.useDHCP = true;

    defaultGateway = {
      address = "10.0.0.1";
      interface = "enp5s0";
    };
  };
}
