{ lib, pkgs, ... }:

{
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_hardened;
}
