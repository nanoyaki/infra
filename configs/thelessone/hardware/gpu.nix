{
  boot.blacklistedKernelModules = [
    "nouveau"
    # integrated gpu
    "amdgpu"
  ];

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

  environment.variables.LIBVA_DRIVER_NAME = "iHD";

  services.xserver.videoDrivers = [ "modesetting" ];
}
