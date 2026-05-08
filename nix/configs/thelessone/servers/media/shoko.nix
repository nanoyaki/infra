{
  flake.nixosModules.thelessone-shoko =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    {
      services.shoko = {
        enable = true;
        plugins = with pkgs; [
          shokofin
          luarenamer
        ];
      };

      users.users.shoko = {
        isSystemUser = true;
        inherit (config.thelessone.arr) group;
        home = config.systemd.services.shoko.environment.SHOKO_HOME;
        homeMode = toString config.systemd.services.shoko.serviceConfig.StateDirectoryMode;
      };

      systemd.services.shoko.wantedBy = lib.mkForce [ "server-services.nix" ];
      systemd.services.shoko.unitConfig.RequiresMountsFor = "/mnt/raid";
      systemd.services.shoko.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "shoko";
        Group = config.thelessone.arr.group;
      };

      thelessone.caddy.vHost."shoko.theless.one" = {
        proxy.port = 8111;
        pangolin.name = "Shoko";
      };

      systemd.services.borgbackup-job-shoko.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.shoko = {
        repo = "/mnt/raid/borgbackup/shoko";
        doInit = true;

        paths = "/var/lib/shoko";

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
