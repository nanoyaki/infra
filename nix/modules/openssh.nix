{
  flake.nixosModules.openssh =
    { lib, config, ... }:

    let
      id_nadesiko = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGTdis9sEaWC/dHRq6a5sTrcBQmQuDQ+OxzJQuhnx/daAAAABHNzaDo=";
      id_hasu = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFRFwcPIHwwoaGk+SOQITBgdWZoLsBuYnwpiWJcf78uzAAAAC3NzaDpkZWZhdWx0";
    in

    {
      services.openssh = {
        enable = true;
        openFirewall = true;

        settings.PermitRootLogin = "prohibit-password";
        settings.PasswordAuthentication = false;
      };

      systemd.services.sshd = {
        unitConfig.DefaultDependencies = false;
        serviceConfig.Restart = "always";
      };

      services.fail2ban = lib.mapAttrs (_: v: lib.mkDefault v) {
        enable = true;
        maxretry = 5;
        bantime-increment.enable = true;
        bantime-increment.maxtime = "5w";
      };

      users.users.root.openssh.authorizedKeys.keys = [
        id_nadesiko
        id_hasu
      ];
      users.users.${config.self.mainUser}.openssh.authorizedKeys.keys = [
        id_nadesiko
        id_hasu
      ];
    };
}
