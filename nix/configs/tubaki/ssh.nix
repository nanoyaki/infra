{
  flake.nixosModules.tubaki-ssh =
    { config, ... }:

    let
      inherit (config) sec;
    in

    {
      sec."ssh/ed25519" = { };
      sops.age.sshKeyPaths = [ "/root/id_tubaki" ];

      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime-increment = {
          enable = true;
          maxtime = "1w";
        };
      };

      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFZy6kSJCjDNC1j58mFtcdfesFaFSb67F2psuwAiIPk id_tubaki_deployment"
      ];
      services.openssh.generateHostKeys = false;
      services.openssh.hostKeys = [
        {
          type = "ed25519";
          path = sec."ssh/ed25519".path;
        }
      ];
    };
}
