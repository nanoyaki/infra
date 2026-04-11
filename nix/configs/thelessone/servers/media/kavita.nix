{
  flake.nixosModules.thelessone-kavita =
    { config, ... }:

    {
      sops.secrets.kavita = { };

      services.kavita = {
        enable = true;
        tokenKeyFile = config.sops.secrets.kavita.path;
        settings.Port = 3300;
      };

      thelessone.caddy.vHost."books.theless.one" = {
        extraConfig = ''
          encode gzip
        '';
        proxy.port = config.services.kavita.settings.Port;
        useVpn = true;
      };

      services.borgbackup.jobs.kavita = {
        repo = "thelessone-borg@10.0.0.6:kavita";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
        doInit = true;

        paths = config.services.kavita.settings.Port;

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
