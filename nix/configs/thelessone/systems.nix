{ inputs, ... }:

{
  flake.nixosModules.thelessone-systems = {
    environment.etc."systems/thelessnas".source =
      inputs.self.nixosConfigurations.thelessnas.config.system.build.toplevel;
    environment.etc."systems/sentinel".source =
      inputs.self.nixosConfigurations.sentinel.config.system.build.toplevel;
  };
}
