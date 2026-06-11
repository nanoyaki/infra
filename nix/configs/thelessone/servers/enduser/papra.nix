{
  flake.nixosModules.thelessone-papra =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.papra = 8008;
      dmn.papra = "papra.theless.one";

      systemd.services.papra.wantedBy = lib.mkForce [ "server-services.target" ];
      services.papra.enable = true;
      services.papra.environment = {
        SERVER_SERVE_PUBLIC_DIR = true;
        PORT = prt.papra;
        DATABASE_URL = "file:/var/lib/papra/db.sqlite";
        DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/var/lib/papra/local-documents";
        APP_BASE_URL = "https://${dmn.papra}";
      };

      thelessone.caddy.vHost.${dmn.papra} = {
        proxy.port = prt.papra;
        useTailnet = true;
      };

      thelessone.backups.papra.paths = [ "/var/lib/papra" ];
    };
}
