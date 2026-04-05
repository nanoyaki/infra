{
  flake.nixosModules.thelessnas-ssh =
    { pkgs, config, ... }:

    let
      openssh.authorizedKeys.keys = [
        # id_deployment_thelessnas
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6a6yxA1AaSmrf/0Xqvyl6m6QcafD9LU93qEFCmI9Ce"
        # TODO: migrate over time
        # id_deployment_thelessnas_new
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDJK71DAZOFN6oB3RfmqmIF1lXf5Le6i/uEuH7GOCg/"
      ];
    in

    {
      sops.secrets.hostkey-rsa = { };
      sops.secrets.hostkey-ed25519 = { };

      services.openssh.hostKeys = [
        {
          type = "rsa";
          inherit (config.sops.secrets.hostkey-rsa) path;
        }
        {
          type = "ed25519";
          inherit (config.sops.secrets.hostkey-ed25519) path;
        }
      ];

      users.users.root = { inherit openssh; };
      users.users.${config.self.mainUser} = { inherit openssh; };

      # for deployment
      environment.systemPackages = [ pkgs.tmux ];

      services.openssh.knownHosts = {
        # Thelessone
        "10.0.0.5".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMMGaMOd8S0N/fUetBkdMehGP47/88C8LDjobmuvwjS";

        # Self
        "10.0.0.6".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqlQS9C6tms9vFdb0tuaudzCFMH57xcBYnkT3FQVdba";
      };
    };
}
