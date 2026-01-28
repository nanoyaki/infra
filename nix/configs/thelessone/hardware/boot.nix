{
  flake.nixosModules.thelessone-boot =
    { pkgs, ... }:

    {
      boot = {
        loader.efi.canTouchEfiVariables = true;
        loader.efi.efiSysMountPoint = "/boot";
      };

      boot.kernelPackages = pkgs.linuxKernel.packageAliases.linux_latest;
    };
}
