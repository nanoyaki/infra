{
  flake.nixosModules.thelessone-actual =
    { lib, config, ... }:

    let
      cfg = config.services.actual;
    in

    {
      systemd.services.actual.wantedBy = lib.mkForce [ "server-services.nix" ];
      services.actual = {
        enable = true;
        openFirewall = true;
        settings.port = 7500;
      };

      thelessone.caddy.vHost."finances.theless.one" = {
        proxy = { inherit (cfg.settings) port; };
        pangolin.name = "Actual";
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
