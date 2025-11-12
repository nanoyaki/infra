{
  networking = {
    useDHCP = true;
    interfaces.enp9s0.useDHCP = true;

    defaultGateway = {
      address = "10.0.0.1";
      interface = "enp9s0";
    };
  };
}
