{
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
    computeRuntime = "default";
    vaapiDriver = null; # use vaapi and media driver
    enableHybridCodec = true;
  };

  services.xserver.videoDrivers = [
    "modesetting"
    "xe"
  ];
}
