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

      services.newt.blueprint.private-resources.kavita = {
        name = "Kavita";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.kavita.settings.Port;
        udp-ports = "";
        alias = "books.theless.one";
        roles = [ "Member" ];
      };

      systemd.services.borgbackup-job-kavita.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.kavita = {
        repo = "/mnt/raid/borgbackup/kavita";
        doInit = true;

        paths = config.services.kavita.dataDir;

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
