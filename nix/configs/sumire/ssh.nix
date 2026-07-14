{
  flake.nixosModules.sumire-ssh =
    { config, ... }:

    let
      inherit (config) sec;
    in

    {
      sec."ssh/ed25519" = { };
      sops.age.sshKeyPaths = [ "/root/id_sumire" ];

      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuZd1r/tPRXIRXjQZYNNTaOzEVMc1xLIMNDRJam0L88 is_sumire_deployment"
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
