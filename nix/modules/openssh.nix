{
  flake.nixosModules.openssh = {
    services.openssh = {
      enable = true;
      openFirewall = true;

      # root login is necessary for
      # deployments at the moment
      # settings.PermitRootLogin = "no";
      settings.PasswordAuthentication = false;
    };

    systemd.services.sshd = {
      unitConfig.DefaultDependencies = false;
      serviceConfig.Restart = "always";
    };

    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime-increment.enable = true;
    };
  };
}
