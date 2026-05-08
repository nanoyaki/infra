{ inputs, ... }:

{
  flake.nixosModules.thelessone-filesystems = {
    imports = [
      inputs.nixos-hardware.nixosModules.common-pc-ssd
    ];

    boot.supportedFilesystems.nfs = true;

    fileSystems."/mnt/raid" = {
      device = "10.0.0.6:/moon";
      fsType = "nfs";
      options = [
        "nfsvers=4.2"
        "_netdev"
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=60s"
        "x-systemd.mount-timeout=60s"
      ];
    };

    fileSystems."/boot" = {
      device = "/dev/nvme0n1p2";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    fileSystems."/" = {
      device = "/dev/nvme0n1p1";
      fsType = "btrfs";
    };
  };
}
