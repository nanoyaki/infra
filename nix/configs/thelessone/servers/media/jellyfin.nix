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

      thelessone.caddy.vHost."jellyfin.theless.one" = {
        proxy.port = 8096;
        useVpn = true;
      };

      users.users.${config.services.jellyfin.user}.extraGroups = [
        "video"
        "render"
      ];

      services.borgbackup.jobs.jellyfin = {
        repo = "thelessone-borg@10.0.0.6:jellyfin";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
