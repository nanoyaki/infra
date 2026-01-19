let
  id_nadesiko = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGTdis9sEaWC/dHRq6a5sTrcBQmQuDQ+OxzJQuhnx/daAAAABHNzaDo=";
  id_sentinel_deployment = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGt26uRk9jIiQKB4pW0FjndllXzNEIWeXfJ47QtixSg";
in

{
  users.users.root.openssh.authorizedKeys.keys = [
    id_nadesiko
    id_sentinel_deployment
  ];

  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "yes";
  };

  nanoSystem.deployment.addresses."85.215.152.236" = {
    targetUser = "root";
    publicKey = id_sentinel_deployment;
  };
}
