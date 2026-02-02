{
  flake.nixosModules.gnome =
    { lib, pkgs, ... }:

    {
      services.displayManager = {
        defaultSession = "gnome";

        sddm.enable = true;
        sddm.wayland.enable = true;
      };

      services.desktopManager.gnome.enable = true;

      programs.dconf = {
        enable = true;
        profiles.user.databases = [
          {
            settings."org/gnome/settings-daemon/plugins/power" = {
              sleep-inactive-ac-type = "nothing";
              sleep-inactive-battery-type = "nothing";
              sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
              sleep-inactive-battery-timeout = lib.gvariant.mkInt32 0;
            };

            settings."org/gnome/desktop/media-handling" = {
              automount = false;
              automount-open = false;
              autorun-never = true;
            };
          }
        ];
      };

      environment.gnome.excludePackages = with pkgs; [
        papers
        evince
        snapshot
        geary
        totem
        simple-scan
        gnome-maps
        epiphany
        cheese
        yelp
        gnome-disk-utility
        gnome-tour
        gnome-contacts
        gnome-music
        gnome-console
        gnome-weather
        gnome-connections
        gnome-terminal
      ];

      programs.nautilus-open-any-terminal.enable = true;
      programs.nautilus-open-any-terminal.terminal = "alacritty";
    };
}
