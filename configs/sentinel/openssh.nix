{ lib, ... }:

let
  id_nadesiko = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGTdis9sEaWC/dHRq6a5sTrcBQmQuDQ+OxzJQuhnx/daAAAABHNzaDo=";
  id_sentinel_deployment = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGt26uRk9jIiQKB4pW0FjndllXzNEIWeXfJ47QtixSg";
in

{
  users.users = {
    root.openssh.authorizedKeys.keys = [
      id_nadesiko
      id_sentinel_deployment
    ];

    sentinel.openssh.authorizedKeys.keys = [
      id_nadesiko
      id_sentinel_deployment
    ];
  };

  services.openssh = {
    enable = lib.mkForce true;
    openFirewall = true;

    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };

    knownHosts."at01.theless.one".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMMGaMOd8S0N/fUetBkdMehGP47/88C8LDjobmuvwjS";
  };

  nanoSystem.deployment.addresses."85.215.152.236" = {
    targetUser = "root";
    publicKey = id_sentinel_deployment;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime-increment.enable = true;
  };
}
