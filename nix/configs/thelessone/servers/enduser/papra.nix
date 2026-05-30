{
  flake.nixosModules.thelessone-papra =
    { lib, config, ... }:

    let
      cfg = config.services.papra;
    in

    {
      systemd.services.papra.wantedBy = lib.mkForce [ "server-services.target" ];
      services.papra.enable = true;
      services.papra.environment = {
        SERVER_SERVE_PUBLIC_DIR = true;
        PORT = 1221;
        DATABASE_URL = "file:/var/lib/papra/db.sqlite";
        DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/var/lib/papra/local-documents";
        APP_BASE_URL = "https://papra.theless.one";
      };

      thelessone.caddy.vHost."papra.theless.one" = {
        proxy.port = cfg.environment.PORT;
        useTailnet = true;
      };

      thelessone.backups.papra.paths = [ "/var/lib/papra" ];
    };
}
