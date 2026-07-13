{ inputs, ... }:

{
  flake.nixosModules.sops =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib) mkAliasOptionModule;
    in

    {
      imports = [
        inputs.sops-nix.nixosModules.default
        (mkAliasOptionModule [ "sec" ] [ "sops" "secrets" ])
        (mkAliasOptionModule [ "tpl" ] [ "sops" "templates" ])
        (mkAliasOptionModule [ "plh" ] [ "sops" "placeholder" ])
      ];

      environment.systemPackages = [ pkgs.sops ];
      sops = {
        defaultSopsFormat = "yaml";
        age.keyFile = lib.mkDefault "${config.self.mainUserHome}/.config/sops/age/keys.txt";
      };
    };
}
