{ inputs, ... }:

{
  imports = [
    ./gpu.nix
    ./boot.nix
    ./mounts.nix

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  services.no-rgb.enable = false;

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  zramSwap.enable = true;
}
