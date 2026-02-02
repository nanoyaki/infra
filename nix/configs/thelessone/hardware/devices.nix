{ inputs, ... }:

{
  flake.nixosModules.thelessone-devices =
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

      boot.kernelModules = [
        "it87"
        "r8125"
      ];
      boot.extraModulePackages = [
        config.boot.kernelPackages.it87
        config.boot.kernelPackages.r8125
      ];
      boot.extraModprobeConfig = ''
        options it87 force_id=0x8628
      '';
    };
}
