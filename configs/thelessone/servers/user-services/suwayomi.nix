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

  sops.secrets."restic/suwayomi" = { };

  config'.restic.backups.suwayomi = {
    repository = "/mnt/raid/backups/suwayomi";
    passwordFile = config.sops.secrets."restic/suwayomi".path;

    basePath = config.services.suwayomi.dataDir;

    timerConfig.OnCalendar = "daily";
  };
}
