{ inputs, ... }:

{
  flake.nixosModules.sops =
    { pkgs, config, ... }:

    {
      imports = [ inputs.sops-nix.nixosModules.default ];

      environment.systemPackages = [ pkgs.sops ];
      sops = {
        defaultSopsFormat = "yaml";
        age.keyFile = "${config.self.mainUserHome}/.config/sops/age/keys.txt";
      };
    };
}
