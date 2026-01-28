{
  flake.nixosModules.thelessone-desktop =
    { pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [
        tmux
        discord
        prismlauncher
      ];
    };
}
