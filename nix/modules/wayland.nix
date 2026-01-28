{
  flake.nixosModules.wayland =
    { config, ... }:

    {
      services.displayManager.autoLogin = {
        enable = true;
        user = config.self.mainUser;
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GDK_BACKEND = "wayland";
      };

      services.libinput.mouse.accelProfile = "flat";
      services.xserver.xkb.layout = "de";
    };

  flake.homeModules.wayland = {
    xdg.autostart.enable = true;
  };
}
