{ inputs, ... }:

{
  flake.nixosConfigurations.sumire = inputs.nixpkgs.lib.nixosSystem {
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
      sumire-system
      sumire-disks
      sumire-ssh
      sumire-boot
      sumire-host
      sumire-acme
      sumire-devices
      sumire-dns
      sumire-continuwuity
      sumire-livekit
      sumire-coturn
      sumire-caddy
      sumire-pocket-id
      sumire-knot-resolver
    ];
  };

  flake.homeConfigurations.sumire = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      inherit (inputs.self.nixosConfigurations.sumire.config.nixpkgs) config;
    };
    modules = with inputs.self.homeModules; [
      homeManager
      nix
      shell
      sumire-system
    ];
  };

  flake.nixosModules.sumire-system =
    { config, ... }:

    {
      sops.age.keyFile = null;
      sops.defaultSopsFile = ./secrets.yaml;
      programs.nh.flake = "${config.self.mainUserHome}/flake";

      self.mainUser = "sumire";
      self.mainUserHome = "/home/sumire";
      sops.secrets."users/sumire".neededForUsers = true;
      users.users.sumire = {
        isNormalUser = true;
        description = "Sumire";
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."users/sumire".path;
      };

      home-manager.users.sumire.imports = with inputs.self.homeModules; [ sumire-system ];
      home-manager.sharedModules = with inputs.self.homeModules; [
        homeManager
        nix
        shell
      ];

      nixpkgs.hostPlatform.system = "x86_64-linux";
      system.stateVersion = "26.11";
    };

  flake.homeModules.sumire-system = {
    home.username = "sumire";
    home.homeDirectory = "/home/sumire";
    home.stateVersion = "26.11";
  };
}
