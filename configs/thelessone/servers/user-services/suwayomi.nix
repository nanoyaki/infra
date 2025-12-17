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
  services.suwayomi = {
    enable = true;

    package = pkgs.suwayomi-server;

    instances = {
      thomas = mkInstance 4555;
      niklas = mkInstance 4556;
      hana = mkInstance 4557;
      mei = mkInstance 4558;
    };
  };

  config'.caddy.vHost = {
    "manga.theless.one" = {
      proxy = { inherit (cfg.thomas.settings.server) port; };
      useVpn = true;
    };
    "nik-manga.theless.one" = {
      proxy = { inherit (cfg.niklas.settings.server) port; };
      useVpn = true;
    };
    "hana-manga.theless.one" = {
      proxy = { inherit (cfg.hana.settings.server) port; };
      useVpn = true;
    };
    "mei-manga.theless.one" = {
      proxy = { inherit (cfg.mei.settings.server) port; };
      useVpn = true;
    };
  };

  services.borgbackup.jobs.suwayomi = {
    repo = "thelessone-borg@10.0.0.6:suwayomi";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
}
