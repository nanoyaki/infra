{
  flake.nixosModules.sentinel-devices =
    { modulesPath, ... }:

    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      hardware.facter.reportPath = ./facter.json;
    };
}
