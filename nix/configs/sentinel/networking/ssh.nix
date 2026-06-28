{ inputs, ... }:

{
  flake.nixosModules.sentinel-ssh =
    { lib, config, ... }:

    let
      inherit (config) prt;

      thelessone = inputs.self.nixosConfigurations.thelessone.config;

      id_nadesiko = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGTdis9sEaWC/dHRq6a5sTrcBQmQuDQ+OxzJQuhnx/daAAAABHNzaDo=";
      id_sentinel_deployment = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGt26uRk9jIiQKB4pW0FjndllXzNEIWeXfJ47QtixSg";
      id_hasu = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFRFwcPIHwwoaGk+SOQITBgdWZoLsBuYnwpiWJcf78uzAAAAC3NzaDpkZWZhdWx0";
    in

    {
      prt.ssh-backup = 2222;

      services.openssh.openFirewall = true;
      services.openssh.ports = with prt; [
        ssh
        ssh-backup
      ];

      users.users = {
        root.openssh.authorizedKeys.keys = [
          id_nadesiko
          id_sentinel_deployment
          id_hasu
        ];

        sentinel.openssh.authorizedKeys.keys = [
          id_nadesiko
          id_sentinel_deployment
          id_hasu
        ];
      };

      services.openssh.knownHosts.${thelessone.dmn.self-fqdn}.publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMMGaMOd8S0N/fUetBkdMehGP47/88C8LDjobmuvwjS";

      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime-increment.enable = true;

        jails.sshd = lib.mkForce { };
      };
    };
}
