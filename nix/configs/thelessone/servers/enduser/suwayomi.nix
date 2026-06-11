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
      inherit (config) prt dmn;

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
    in

    {
      imports = [ inputs.self.nixosModules.suwayomi ];

      systemd.services = {
        suwayomi-mei.wantedBy = lib.mkForce [ "server-services.target" ];
        suwayomi-hana.wantedBy = lib.mkForce [ "server-services.target" ];
        suwayomi-thomas.wantedBy = lib.mkForce [ "server-services.target" ];
      };

      prt = {
        suwayomi-thomas = 8026;
        suwayomi-hana = 8027;
        suwayomi-mei = 8028;
      };

      dmn = {
        suwayomi-thomas = "manga.theless.one";
        suwayomi-hana = "hana-manga.theless.one";
        suwayomi-mei = "mei-manga.theless.one";
      };

      services.suwayomi = {
        enable = true;

        package = pkgs.suwayomi-server;

        instances = {
          thomas = mkInstance prt.suwayomi-thomas;
          hana = mkInstance prt.suwayomi-hana;
          mei = mkInstance prt.suwayomi-mei;
        };
      };

      thelessone.caddy.vHost = {
        ${dmn.suwayomi-thomas} = {
          proxy.port = prt.suwayomi-thomas;
          useTailnet = true;
        };

        ${dmn.suwayomi-hana} = {
          proxy.port = prt.suwayomi-hana;
          useTailnet = true;
        };

        ${dmn.suwayomi-mei} = {
          proxy.port = prt.suwayomi-mei;
          useTailnet = true;
        };
      };

      thelessone.backups.suwayomi.paths = [ config.services.suwayomi.dataDir ];
    };
}
