{
  flake.nixosModules.networking =
    { lib, ... }:

    {
      networking.useDHCP = lib.mkDefault true;
      networking.nameservers = lib.mkDefault [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
      ];
    };
}
