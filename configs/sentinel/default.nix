{ lib', inputs, ... }:

{
  flake.nixosConfigurations.sentinel = lib'.systems.mkServer {
    inherit inputs;
    hostname = "sentinel";
    users.sentinel = {
      isMainUser = true;
      isSuperuser = true;
      hashedPasswordSopsKey = "users/sentinel";
      home.stateVersion = "26.05";
    };
    stateVersion = "25.12";
    config =
      { config, ... }:

      {
        imports = [
          inputs.disko.nixosModules.disko
          ./hardware

          ./openssh.nix
        ];

        sops.secrets."users/root".neededForUsers = true;
        users.users.root.hashedPasswordFile = config.sops.secrets."users/root".path;

        nanoSystem.sops.enable = true;
        nanoSystem.sops.defaultSopsFile = ./secrets/host.yaml;

        system.stateVersion = "26.05";
      };
  };
}
