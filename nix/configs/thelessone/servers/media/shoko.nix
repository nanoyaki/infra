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

      systemd.services.shoko.unitConfig.RequiresMountsFor = "/mnt/raid";
      systemd.services.shoko.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "shoko";
        Group = config.thelessone.arr.group;
      };

      thelessone.caddy.vHost."shoko.theless.one" = {
        proxy.port = 8111;
        useVpn = true;
      };

      services.borgbackup.jobs.shoko = {
        repo = "thelessone-borg@10.0.0.6:shoko";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
