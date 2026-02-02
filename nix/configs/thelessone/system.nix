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
      homeManager
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
      inherit (inputs.self.nixosConfigurations.thelessone.config.nixpkgs) config;
    };
    modules = with inputs.self.homeModules; [
      homeManager
      shell
      terminal
      fonts
      thelessone-system
      thelessone-desktop
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

      nixpkgs.allowUnfreeNames = [
        "intel-ocl"
        "minecraft-server"
        # dependency of sabnzbd
        "unrar"
      ];

      system.stateVersion = "24.11";
    };

  flake.homeModules.thelessone-system = {
    home.stateVersion = "24.11";
  };
}
