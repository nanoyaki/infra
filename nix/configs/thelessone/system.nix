{ inputs, ... }:

{
  flake.nixosConfigurations.thelessone = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = with inputs.self.nixosModules; [
      common
      nix
      sops
      networking
      openssh
      homeManager
      shell
      audio
      wayland
      vscode
      thelessone-system
    ];
  };

  flake.homeConfigurations.thelessone = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      inherit (inputs.self.nixosConfigurations.thelessone.config.nixpkgs) config;
    };
    modules = with inputs.self.homeModules; [ ];
  };

  flake.nixosModules.thelessone-system =
    { config, ... }:

    {
      sops.defaultSopsFile = ./secrets.yaml;
      programs.nh.flake = "${config.self.mainUserHome}/flake";

      sops.secrets."users/thelessone".neededForUsers = true;
      users.users.thelessone = {
        isNormalUser = true;
        description = "Thelessone";
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."users/thelessone".path;
      };

      networking = {
        hostId = "f617b7b6";
        hostName = "thelessone";
        domain = "theless.one";
        fqdn = "at01.theless.one";
      };

      system.stateVersion = "24.11";
    };

  flake.homeModules.thelessone-system = {
    home.stateVersion = "24.11";
  };
}
