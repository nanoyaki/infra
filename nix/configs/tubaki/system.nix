{ inputs, ... }:

{
  flake.nixosConfigurations.tubaki = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = with inputs.self.nixosModules; [
      common
      homeManager
      nix
      sops
      networking
      openssh
      shell
      dns
      tubaki-system
      tubaki-disks
      tubaki-ssh
      tubaki-boot
      tubaki-host
      tubaki-acme
      tubaki-devices
      tubaki-dns
      tubaki-web
      tubaki-mail
    ];
  };

  flake.homeConfigurations.tubaki = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      inherit (inputs.self.nixosConfigurations.tubaki.config.nixpkgs) config;
    };
    modules = with inputs.self.homeModules; [
      homeManager
      nix
      shell
      tubaki-system
    ];
  };

  flake.nixosModules.tubaki-system =
    { config, ... }:

    {
      sops.age.keyFile = null;
      sops.defaultSopsFile = ./secrets.yaml;
      programs.nh.flake = "${config.self.mainUserHome}/flake";

      self.mainUser = "tubaki";
      self.mainUserHome = "/home/tubaki";
      sops.secrets."users/tubaki".neededForUsers = true;
      users.users.tubaki = {
        isNormalUser = true;
        description = "Tubaki";
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."users/tubaki".path;
      };

      home-manager.users.tubaki.imports = with inputs.self.homeModules; [ tubaki-system ];
      home-manager.sharedModules = with inputs.self.homeModules; [
        homeManager
        nix
        shell
      ];

      nixpkgs.hostPlatform.system = "x86_64-linux";
      system.stateVersion = "26.11";
    };

  flake.homeModules.tubaki-system = {
    home.username = "tubaki";
    home.homeDirectory = "/home/tubaki";
    home.stateVersion = "26.11";
  };
}
