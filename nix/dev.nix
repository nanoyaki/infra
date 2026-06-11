{ inputs, ... }:

{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  debug = true;

  perSystem =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib) mapAttrs' nameValuePair;
    in

    {
      pre-commit = {
        check.enable = true;
        settings.hooks = {
          statix.enable = true;
          flake-checker.enable = true;
          nixfmt.enable = true;
          deadnix.enable = true;
        };
      };

      checks = mapAttrs' (n: nameValuePair "devShell-${n}") config.devShells;

      devShells.default = config.pre-commit.devShell.overrideAttrs (prevAttrs: {
        buildInputs = (prevAttrs.buildInputs or [ ]) ++ (with pkgs; [ git ]);
      });

      formatter = pkgs.nixfmt-tree;
    };

  systems = import inputs.systems;
}
