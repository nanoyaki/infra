{
  flake.nixosModules.gnome =
    { pkgs, ... }:

    {
      services.displayManager = {
        defaultSession = "gnome";

        sddm.enable = true;
        sddm.wayland.enable = true;
      };

      services.desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = ''
          [org.gnome.settings-daemon.plugins.power]
          sleep-inactive-ac-type="nothing"

          [org.gnome.desktop.media-handling]
          automount=false
          automount-open=false
          autorun-never=true
        '';
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

      # Disable sleep because gnome is silly
      systemd.targets.hibernate.enable = false;
      systemd.targets.suspend.enable = false;
      systemd.targets.sleep.enable = false;
    };
}
