{ inputs, ... }:

{
  flake.nixosModules.thelessone-valheim =
    {
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

      services.borgbackup.jobs.valheim = {
        repo = "thelessone-borg@10.0.0.6:valheim";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
        doInit = true;

        paths = backupPath;
        patterns = [
          "+ ${backupPath}/Test12.*"
          "- **"
        ];

        encryption.mode = "none";
        compression = "zstd";

        startAt = "*:0/15";
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
