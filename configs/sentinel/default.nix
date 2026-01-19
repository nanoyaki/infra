{ lib', inputs, ... }:

{
  flake.nixosConfigurations.sentinel = lib'.systems.mkServer {
    inherit inputs;
    hostname = "sentinel";
    users.sentinel = {
      isMainUser = true;
      isSuperuser = true;
      # hashedPasswordSopsKey = "users/sentinel"; keep null for now
      home.stateVersion = "26.05";
    };
    stateVersion = "25.12";
    config = {
      imports = [
        inputs.disko.nixosModules.disko
        ./hardware

        ./openssh.nix
      ];

      nanoSystem.sops.enable = false;

      system.stateVersion = "26.05";
    };
  };
}
