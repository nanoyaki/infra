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

      services.newt.blueprint.public-resources.valheim = {
        name = "Valheim";
        protocol = "tcp";
        proxy-port = 2456;
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            port = 2456;
          }
        ];
      };

      systemd.services.borgbackup-job-valheim.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.valheim = {
        repo = "/mnt/raid/borgbackup/valheim";
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
