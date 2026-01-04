{
  self,
  lib,
  pkgs,
  config,
  ...
}:

# TODO: setup nixos impermanence

{
  nixpkgs.overlays = [
    (_: prev: {
      weston = prev.weston.overrideAttrs (prevAttrs: {
        mesonFlags = prevAttrs.mesonFlags or [ ] ++ [ (prev.lib.mesonBool "backend-vnc" false) ];
      });
    })
  ];

  config' = {
    librewolf.enable = true;
    theming.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # vesktop
    discord

    vscodium
    tmux
    prismlauncher
  ];

  security.sudo.extraRules = [
    {
      users = [ config.nanoSystem.mainUserName ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # for deployment
  environment.etc."systems/thelessnas".source =
    self.nixosConfigurations.thelessnas.config.system.build.toplevel;

  systemd.tmpfiles.settings."10-restic-backups"."/mnt/raid/backups".d = {
    mode = "0700";
    user = "root";
    group = "wheel";
  };

  # Disable sleep targets
  systemd.targets.hibernate.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.sleep.enable = false;

  environment.shells = with pkgs; [ zsh ];

  services.displayManager.gdm.enable = lib.mkForce false;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
}
