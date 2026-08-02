{ inputs, ... }:

{
  flake.nixosModules.thelessone-gpu =
    _:

    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-gpu-intel
      ];

      boot.blacklistedKernelModules = [
        "nouveau"
        # integrated gpu
        "amdgpu"
        "i915"
      ];

      boot.kernelModules = [ "xe" ];
      boot.extraModprobeConfig = ''
        options xe force_probe=6021
      '';

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      hardware.intelgpu = {
        driver = "xe";
        loadInInitrd = true;
        enableHybridCodec = true;

        # OpenCL
        computeRuntime = "default";
        vaapiDriver = null; # use vaapi and media driver
      };

      services.xserver.videoDrivers = [ "modesetting" ];
    };
}
