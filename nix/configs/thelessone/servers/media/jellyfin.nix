{
  flake.nixosModules.thelessone-jellyfin =
    { pkgs, config, ... }:

    let
      backupPath = "/var/lib/jellyfin";
    in

    {
      services.jellyfin = {
        enable = true;
        package = pkgs.jellyfin.override {
          jellyfin-web = pkgs.jellyfin-web-with-plugins;
        };
        inherit (config.thelessone.arr) group;
      };

      services.newt.blueprint.private-resources.jellyfin = {
        name = "Jellyfin";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = "8096";
        udp-ports = "";
        alias = "jellyfin.theless.one";
        roles = [ "Member" ];
      };

      users.users.${config.services.jellyfin.user}.extraGroups = [
        "video"
        "render"
      ];

      systemd.services.borgbackup-job-jellyfin.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.jellyfin = {
        repo = "/mnt/raid/borgbackup/jellyfin";
        doInit = true;

        paths = backupPath;
        patterns = [
          "- ${backupPath}/metadata/library"
          "- ${backupPath}/data/subtitles"
        ];

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
