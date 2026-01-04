{
  description = "Hana's NixOS System flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-compat.url = "github:NixOS/flake-compat";
    systems.url = "github:nix-systems/default-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    lib-aggregate = {
      url = "github:nix-community/lib-aggregate";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        lib-aggregate.follows = "lib-aggregate";
      };
    };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
      };
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        nur.follows = "nur";
        systems.follows = "systems";
      };
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    valheim-server = {
      url = "github:hamburger1984/valheim-server-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snm = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        git-hooks.follows = "git-hooks-nix";
      };
    };
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    wkeys = {
      url = "github:nanoyaki/wkeys?dir=wkeys";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.home-manager.follows = "home-manager";
    };

    # own stuff
    nanopkgs = {
      url = "git+https://git.theless.one/nanoyaki/nanopkgs.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "git-hooks-nix";
        flake-compat.follows = "flake-compat";
      };
    };
    killheal.url = "git+https://git.theless.one/thelessone/KillHeal.git";
    nanolib = {
      url = "git+https://git.theless.one/nanoyaki/nanolib.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
      };
    };
    nanomodules = {
      url = "git+https://git.theless.one/nanoyaki/nanomodules.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        nanolib.follows = "nanolib";
        systems.follows = "systems";
      };
    };
    nix-scpsl = {
      url = "git+https://git.theless.one/nanoyaki/nix-scpsl.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    discord-events-to-ics = {
      url = "github:nanoyaki/discord-events-to-ics";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
      };
    };
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {
      _module.args.lib' = inputs.nanolib.lib;

      imports = [
        inputs.git-hooks-nix.flakeModule

        ./modules

        ./configs/thelessone
        ./configs/thelessnas
      ];

      perSystem =
        {
          lib,
          pkgs,
          self',
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
              nixfmt-rfc-style.enable = true;
              deadnix.enable = true;
            };
          };

          devShells.default = config.pre-commit.devShell.overrideAttrs (prevAttrs: {
            buildInputs = (prevAttrs.buildInputs or [ ]) ++ (with pkgs; [ git ]);
          });

          checks = mapAttrs' (n: nameValuePair "devShell-${n}") self'.devShells;

          formatter = pkgs.nixfmt-tree;
        };

      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };
}
