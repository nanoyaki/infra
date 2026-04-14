{ inputs, ... }:

{
  flake.nixosModules.thelessone-suwayomi =
    {
      config,
      pkgs,
      ...
    }:

    let
      mkInstance = port: {
        enable = true;

        settings.server = {
          inherit port;
          extensionRepos = map (repo: "https://raw.githubusercontent.com/${repo}/repo/index.min.json") [
            "keiyoushi/extensions"
            "yuzono/manga-repo"
            "Kareadita/tach-extension"
            "Suwayomi/tachiyomi-extension"
          ];

          flareSolverrEnabled = true;
          flareSolverrUrl = "http://localhost:8191";
          flareSolverrSessionName = "suwayomi-${toString port}";
        };
      };

      cfg = config.services.suwayomi.instances;
    in

    {
      imports = [ inputs.self.nixosModules.suwayomi ];

      services.suwayomi = {
        enable = true;

        package = pkgs.suwayomi-server;

        instances = {
          thomas = mkInstance 4555;
          hana = mkInstance 4557;
          mei = mkInstance 4558;
        };
      };

      thelessone.caddy.vHost = {
        "manga.theless.one" = {
          proxy = { inherit (cfg.thomas.settings.server) port; };
          pangolin.name = "Suwayomi Thomas";
        };
        "hana-manga.theless.one" = {
          proxy = { inherit (cfg.hana.settings.server) port; };
          pangolin.name = "Suwayomi Hana";
        };
        "mei-manga.theless.one" = {
          proxy = { inherit (cfg.mei.settings.server) port; };
          pangolin.name = "Suwayomi Mei";
        };
      };

      systemd.services.borgbackup-job-suwayomi.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.suwayomi = {
        repo = "/mnt/raid/borgbackup/suwayomi";
        doInit = true;

        paths = config.services.suwayomi.dataDir;

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
