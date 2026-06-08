{ inputs, ... }:

{
  flake.nixosModules.thelessnas-filesystems =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      zfsCompatibleKernelPackages = lib.filterAttrs (
        name: kernelPackages:
        (builtins.match "linux_[0-9]+_[0-9]+" name) != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
      ) pkgs.linuxKernel.packages;
      latestKernelPackage = lib.last (
        lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
          builtins.attrValues zfsCompatibleKernelPackages
        )
      );
    in
    {
      imports = [ inputs.nixos-hardware.nixosModules.common-pc-ssd ];

      boot = {
        kernelPackages = latestKernelPackage;
        supportedFilesystems.zfs = true;
        zfs.forceImportRoot = false;
        zfs.extraPools = [ "moon" ];
      };

      services.zfs.autoScrub.enable = true;
      systemd.services.zfs-mount.enable = false;
      systemd.services.zfs-share-moon = {
        requires = [ "zfs-import-moon.service" ];
        after = [ "zfs-import-moon.service" ];

        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.zfs} share moon";
          ExecStartPost = "${lib.getExe pkgs.zfs} mount moon";
          Type = "oneshot";
        };
      };

      services.nfs.server.enable = true;
      networking.firewall.allowedTCPPorts = [ 2049 ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/732c4fe7-e780-408f-94f1-70e919db209e";
        fsType = "btrfs";
        options = [ "subvol=@" ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/A69C-9FBB";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };
}
