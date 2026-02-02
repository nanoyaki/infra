{ inputs, ... }:

{
  flake.nixosModules.thelessnas-devices =
    { config, ... }:

    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-cpu-amd
        inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
      ];

      hardware.cpu.amd.updateMicrocode = true;
      zramSwap.enable = true;

      hardware.enableAllFirmware = true;
      hardware.facter.reportPath = ./facter.json;

      boot.kernelModules = [ "r8125" ];
      boot.extraModulePackages = [ config.boot.kernelPackages.r8125 ];
    };
}
