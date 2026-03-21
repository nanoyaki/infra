{
  flake.nixosModules.thelessone-whisparr =
    { config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.whisparr.settings.server.port ];

      # systemd.services.whisparr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.whisparr = {
        enable = false;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."whisparr.theless.one" = {
        proxy.port = config.services.whisparr.settings.server.port;
        useVpn = true;
        enable = false;
      };

      services.borgbackup.jobs.whisparr = {
        enable = false;
        repo = "thelessone-borg@10.0.0.6:whisparr";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
        doInit = true;

        paths = "/var/lib/whisparr";

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
