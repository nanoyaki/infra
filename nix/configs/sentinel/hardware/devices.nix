{
  flake.nixosModules.sentinel-devices =
    { modulesPath, ... }:

    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      hardware.graphics.enable = false;
      hardware.graphics.enable32Bit = false;

      hardware.facter.reportPath = ./facter.json;
    };
}
