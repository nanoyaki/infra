{
  inputs = {
    # Essentials
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    import-tree.url = "github:vic/import-tree";
    systems.url = "github:nix-systems/default";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs = {
      nixpkgs.follows = "nixpkgs";
      lib-aggregate.follows = "lib-aggregate";
      flake-compat.follows = "flake-compat";
    };
    snm.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    snm.inputs = {
      flake-compat.follows = "flake-compat";
      git-hooks.follows = "git-hooks-nix";
      nixpkgs.follows = "nixpkgs";
    };
    copyparty.url = "github:9001/copyparty";
    copyparty.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
    nix-scpsl.url = "github:nanoyaki/nix-scpsl";
    nix-scpsl.inputs = {
      nixpkgs.follows = "nixpkgs";
      steam-fetcher.follows = "steam-fetcher";
    };
    valheim-server.url = "github:hamburger1984/valheim-server-flake";
    valheim-server.inputs = {
      nixpkgs.follows = "nixpkgs";
      # uses a version of steam-fetcher that uses
      # overlays.default instead of overlay
      # steam-fetcher.follows = "steam-fetcher";
    };
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-minecraft.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
      flake-compat.follows = "flake-compat";
    };
    stylix.url = "github:nix-community/stylix";
    stylix.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      systems.follows = "systems";
      nur.follows = "nur";
    };
    discord-events-to-ics.url = "github:nanoyaki/discord-events-to-ics";
    discord-events-to-ics.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
      flake-parts.follows = "flake-parts";
    };
    nixos-branding.url = "github:NixOS/branding";
    nixos-branding.inputs = {
      nixpkgs.follows = "nixpkgs";
      gitignore.follows = "gitignore";
      flake-compat.follows = "flake-compat";
      pre-commit-hooks.follows = "git-hooks-nix";
    };
    killheal.url = "git+https://git.theless.one/thelessone/KillHeal.git";
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";
    nur.inputs.flake-parts.follows = "flake-parts";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.inputs.flake-compat.follows = "flake-compat";
    tangled.url = "git+https://tangled.org/tangled.org/core";
    tangled.inputs.nixpkgs.follows = "nixpkgs";
    tangled.inputs.gomod2nix.follows = "gomod2nix";
    avatar-server.url = "github:nanoyaki/avatar-server";
    avatar-server.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      systems.follows = "systems";
      treefmt-nix.follows = "treefmt-nix";
    };
    nanoyaki-space.url = "git+https://tangled.org/nanoyaki.space/nanoyaki.space";
    nanoyaki-space.flake = false;
    headplane.url = "github:tale/headplane";
    headplane.inputs.nixpkgs.follows = "nixpkgs";
    headplane.inputs.flake-utils.follows = "flake-utils";
    theless-dot-one.url = "git+https://git.theless.one/nanoyaki/theless.one.git";
    theless-dot-one.inputs.nixpkgs.follows = "nixpkgs";
    nixbot.url = "github:Mic92/nixbot";
    nixbot.inputs.nixpkgs.follows = "nixpkgs";
    nixbot.inputs.treefmt-nix.follows = "treefmt-nix";

    # Deduplication
    flake-compat.url = "github:NixOS/flake-compat";
    flake-compat.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    lib-aggregate.url = "github:nix-community/lib-aggregate";
    lib-aggregate.inputs.flake-utils.follows = "flake-utils";
    lib-aggregate.inputs.nixpkgs-lib.follows = "nixpkgs";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
    steam-fetcher.url = "github:nix-community/steam-fetcher";
    steam-fetcher.inputs.nixpkgs.follows = "nixpkgs";
    gomod2nix.url = "github:nix-community/gomod2nix";
    gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
    gomod2nix.inputs.flake-utils.follows = "flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./nix);
}
