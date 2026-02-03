{ inputs, ... }:

{
  flake.nixosConfigurations.thelessone = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = with inputs.self.nixosModules; [
      common
      homeManager
      nix
      sops
      networking
      openssh
      fonts
      shell
      audio
      wayland
      gnome
      vscode
      thelessone-system
      thelessone-boot
      thelessone-devices
      thelessone-filesystems
      thelessone-gpu
      thelessone-networking
      thelessone-wireguard
      thelessone-vopono
      thelessone-systems
      thelessone-ssh
      thelessone-locale
      thelessone-backups
      thelessone-acme
      thelessone-ddns
      thelessone-mailserver
      thelessone-radicale
      thelessone-caddy
      thelessone-vaultwarden
      thelessone-nanoyakiEvents
      thelessone-copyparty
      thelessone-fireshare
      thelessone-forgejo
      thelessone-dashboard
      thelessone-suwayomi
      thelessone-arr
      thelessone-deluge
      thelessone-sabnzbd
      thelessone-flaresolverr
      thelessone-prowlarr
      thelessone-lidarr
      thelessone-radarr
      thelessone-sonarr
      thelessone-whisparr
      thelessone-bazarr
      thelessone-jellyfin
      thelessone-jellyseerr
      thelessone-stash
      thelessone-immich
      thelessone-tandoor
      thelessone-audiobookshelf
      thelessone-actual
      thelessone-scpsl
      # thelessone-valheim
      thelessone-minecraft
      thelessone-minecraftDefaults
      thelessone-minecraftWhitelist
      thelessone-minecraftBanned
      thelessone-minecraftProxy
      thelessone-minecraftSmp
      thelessone-minecraftCreative
      thelessone-minecraftFlat
      thelessone-nonNixMinecraft
      thelessone-desktop
      thelessone-theming
      thelessone-steam
    ];
  };

  flake.homeConfigurations.thelessone = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      inherit (inputs.self.nixosConfigurations.thelessnas.config.nixpkgs) config overlays;
    };
    modules = with inputs.self.homeModules; [
      homeManager
      nix
      shell
      fonts
      thelessone-system
      thelessone-desktop
      thelessone-terminal
      thelessone-theming
      thelessone-xdg
    ];
  };

  flake.nixosModules.thelessone-system =
    { config, ... }:

    {
      sops.defaultSopsFile = ./secrets.yaml;
      programs.nh.flake = "${config.self.mainUserHome}/flake";

      self.mainUser = "thelessone";
      self.mainUserHome = "/home/thelessone";
      sops.secrets."users/thelessone".neededForUsers = true;
      users.users.thelessone = {
        isNormalUser = true;
        description = "Thelessone";
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."users/thelessone".path;
      };

      security.sudo.extraRules = [
        {
          users = [ "thelessone" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      home-manager.users.thelessone.imports = with inputs.self.homeModules; [
        thelessone-system
        thelessone-desktop
        thelessone-terminal
        thelessone-theming
        thelessone-xdg
      ];
      home-manager.sharedModules = with inputs.self.homeModules; [
        homeManager
        nix
        shell
        fonts
      ];

      nixpkgs.allowUnfreeNames = [
        "intel-ocl"
        "minecraft-server"
        # dependency of sabnzbd
        "unrar"
        # firefox addons
        "keepa"
        "languagetool"
        "tampermonkey"
        "betterttv"

        # desktop
        "steamcmd"
        "steam"
        "steam-unwrapped"
        "discord"

        # hardware
        "broadcom-bt-firmware"
        "b43-firmware"
        "xone-dongle-firmware"
        "facetimehd-calibration"
        "facetimehd-firmware"
      ];

      system.stateVersion = "24.11";
    };

  flake.homeModules.thelessone-system = {
    home.username = "thelessone";
    home.homeDirectory = "/home/thelessone";

    home.stateVersion = "24.11";
  };
}
