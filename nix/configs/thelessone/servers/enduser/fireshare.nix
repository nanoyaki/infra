{ inputs, ... }:

{
  flake.nixosModules.thelessone-fireshare =
    { pkgs, config, ... }:

    {
      imports = [ inputs.self.nixosModules.fireshare ];

      sops.secrets = {
        "fireshare/secret-key" = { };
        "fireshare/admin-username" = { };
        "fireshare/admin-password" = { };
      };

      sops.templates."fireshare.env".file = pkgs.writeEnv "fireshare.env.template" {
        ADMIN_USERNAME = config.sops.placeholder."fireshare/admin-username";
        ADMIN_PASSWORD = config.sops.placeholder."fireshare/admin-password";
        SECRET_KEY = config.sops.placeholder."fireshare/secret-key";
      };

      self.fireshare = {
        enable = true;
        backendListenAddress = "127.0.0.1:32254";
        dataDir = "/mnt/raid/fireshare";
        environment.DOMAIN = "fireshare.theless.one";

        environmentFile = config.sops.templates."fireshare.env".path;
      };

      services.caddy.virtualHosts."fireshare.theless.one".useACMEHost = "theless.one";

      services.borgbackup.jobs.fireshare = {
        repo = "thelessone-borg@10.0.0.6:fireshare";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
        doInit = true;

        paths = "/mnt/raid/fireshare";

        encryption.mode = "none";
        compression = "zstd";

        startAt = "daily";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 14;
          weekly = 12;
          monthly = -1;
        };
      };
    };
}
