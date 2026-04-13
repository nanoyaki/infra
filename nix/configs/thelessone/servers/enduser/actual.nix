{
  flake.nixosModules.thelessone-actual =
    { config, ... }:

    let
      cfg = config.services.actual;
    in

    {
      services.actual = {
        enable = true;
        openFirewall = true;
        settings.port = 7500;
      };

      services.newt.blueprint.private-resources.actual = {
        name = "Actual";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = "${toString cfg.settings.port}";
        udp-ports = "";
        alias = "actual.theless.one";
        users = [ "contact@nanoyaki.space" ];
      };

      systemd.services.borgbackup-job-actual.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.actual = {
        repo = "/mnt/raid/borgbackup/actual";
        doInit = true;

        paths = "/var/lib/private/actual";

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
