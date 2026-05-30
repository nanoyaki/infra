{ inputs, ... }:

{
  flake.nixosModules.thelessone-valheim =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      backupPath = "/var/lib/valheim/.config/unity3d/IronGate/Valheim/worlds_local";
    in

    {
      imports = [ inputs.valheim-server.nixosModules.default ];

      sops = {
        secrets.valheim-password = { };
        templates."valheim-password.env".file = pkgs.writeEnv "valheim-password.env.template" {
          VH_SERVER_PASSWORD = config.sops.placeholder.valheim-password;
        };
      };

      systemd.services.valheim.wantedBy = lib.mkForce [ "server-services.target" ];
      services.valheim = {
        enable = true;
        openFirewall = true;
        passwordEnvFile = config.sops.templates."valheim-password.env".path;

        noGraphics = true;
        public = true;
        serverName = "Cozy server x3";
        worldName = "Test12";
        adminList = [ "76561198294979887" ];
      };

      thelessone.backups.valheim.paths = [ backupPath ];
    };
}
