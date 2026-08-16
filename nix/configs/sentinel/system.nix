{ inputs, ... }:

{
  flake.nixosConfigurations.sentinel = inputs.nixpkgs.lib.nixosSystem {
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
      sentinel-system
      sentinel-boot
      sentinel-disks
      sentinel-devices
      sentinel-locale
      sentinel-host
      sentinel-ssh
      sentinel-acme
      sentinel-dns
      sentinel-pds
      sentinel-nanoyaki-space
      sentinel-tangled
      sentinel-caddy
      sentinel-tailscale
    ];
  };

  flake.homeConfigurations.sentinel = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      inherit (inputs.self.nixosConfigurations.sentinel.config.nixpkgs) config overlays;
    };
    modules = with inputs.self.homeModules; [
      homeManager
      nix
      shell
      sentinel-system
    ];
  };

  flake.nixosModules.sentinel-system =
    { config, ... }:

    {
      sops.defaultSopsFile = ./secrets.yaml;
      programs.nh.flake = "${config.self.mainUserHome}/flake";

      self.mainUser = "sentinel";
      self.mainUserHome = "/home/sentinel";
      sops.secrets."users/sentinel".neededForUsers = true;
      users.users.sentinel = {
        isNormalUser = true;
        description = "Sentinel";
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."users/sentinel".path;
      };

      nixpkgs.config.permittedInsecurePackages = [
        "pnpm-9.15.9"
      ];

      home-manager.users.sentinel.imports = with inputs.self.homeModules; [ sentinel-system ];
      home-manager.sharedModules = with inputs.self.homeModules; [
        homeManager
        nix
        shell
      ];

      system.stateVersion = "26.05";
    };

  flake.homeModules.sentinel-system = {
    home.username = "sentinel";
    home.homeDirectory = "/home/sentinel";

    home.stateVersion = "26.05";
  };
}
