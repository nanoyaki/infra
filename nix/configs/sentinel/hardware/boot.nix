{
  flake.nixosModules.sentinel-boot =
    { pkgs, ... }:

    {
      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      boot.kernelPackages = pkgs.linuxKernel.packages.linux_hardened;
    };
}
