{
  flake.nixosModules.thelessone-jellyseerr =
    { config, ... }:

    {
      services.seerr.enable = true;

      thelessone.caddy.vHost."jellyseerr.theless.one" = {
        proxy = { inherit (config.services.seerr) port; };
        useVpn = true;
      };

      services.borgbackup.jobs.jellyseerr = {
        repo = "thelessone-borg@10.0.0.6:jellyseerr";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
        doInit = true;

        paths = "/var/lib/private/jellyseerr";

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
