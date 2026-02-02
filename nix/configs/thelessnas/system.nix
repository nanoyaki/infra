{ inputs, ... }:

{
  flake.nixosConfigurations.thelessnas = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = with inputs.self.nixosModules; [
      common
      homeManager
      nix
      sops
      networking
      openssh
      shell
      thelessnas-system
      thelessnas-boot
      thelessnas-devices
      thelessnas-filesystems
      thelessnas-networking
      thelessnas-wireguard
      thelessnas-locale
      thelessnas-backups
      thelessnas-ssh
    ];
  };

  flake.homeConfigurations.admin = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      inherit (inputs.self.nixosConfigurations.thelessnas.config.nixpkgs) config overlays;
    };
    modules = with inputs.self.homeModules; [
      homeManager
      shell
      terminal
      admin-system
    ];
  };

  flake.nixosModules.thelessnas-system =
    { config, ... }:

    {
      sops.defaultSopsFile = ./secrets.yaml;
      programs.nh.flake = "${config.self.mainUserHome}/flake";

      self.mainUser = "admin";
      self.mainUserHome = "/home/admin";
      sops.secrets."users/admin".neededForUsers = true;
      users.users.admin = {
        isNormalUser = true;
        description = "Admin";
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."users/admin".path;
      };

      system.stateVersion = "24.11";
    };

  flake.homeModules.admin-system = {
    home.username = "admin";
    home.homeDirectory = "/home/admin";

    home.stateVersion = "25.11";
  };
}
