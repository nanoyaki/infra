{
  flake.nixosModules.sumire-boot =
    { pkgs, ... }:

    {
      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      boot.kernelPackages = pkgs.linuxKernel.packageAliases.linux_latest;
    };
}
