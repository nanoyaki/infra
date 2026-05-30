{ inputs, ... }:

{
  flake.nixosModules.thelessone-suwayomi =
    {
      lib,
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

      systemd.services = {
        suwayomi-mei.wantedBy = lib.mkForce [ "server-services.target" ];
        suwayomi-hana.wantedBy = lib.mkForce [ "server-services.target" ];
        suwayomi-thomas.wantedBy = lib.mkForce [ "server-services.target" ];
      };

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
          useTailnet = true;
        };
        "hana-manga.theless.one" = {
          proxy = { inherit (cfg.hana.settings.server) port; };
          useTailnet = true;
        };
        "mei-manga.theless.one" = {
          proxy = { inherit (cfg.mei.settings.server) port; };
          useTailnet = true;
        };
      };

      thelessone.backups.suwayomi.paths = [ config.services.suwayomi.dataDir ];
    };
}
