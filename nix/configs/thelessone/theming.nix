{ inputs, ... }:

{
  flake.nixosModules.thelessone-theming =
    { pkgs, config, ... }:

    {
      imports = [ inputs.stylix.nixosModules.default ];

      stylix = {
        enable = true;
        autoEnable = false;

        cursor = {
          package = pkgs.rose-pine-cursor;
          name = "BreezeX-RosePine-Linux";
          size = 32;
        };

        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        polarity = "dark";

        targets.plymouth = { inherit (config.boot.plymouth) enable; };
      };
    };

  flake.homeModules.thelessone-theming =
    { config, ... }:

    {
      gtk = rec {
        enable = true;

        gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        gtk2.extraConfig = ''
          gtk-application-prefer-dark-theme="true"
        '';

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-menu-images = true;
          gtk-primary-button-warps-slider = true;
          gtk-toolbar-style = 3;
          gtk-decoration-layout = ":minimize,maximize,close";
        };

        gtk4 = { inherit (gtk3) extraConfig; };
      };
    };
}
