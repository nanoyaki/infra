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

      systemd.services.shoko.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.shoko.unitConfig.RequiresMountsFor = "/mnt/raid";
      systemd.services.shoko.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "shoko";
        Group = config.thelessone.arr.group;
      };

      thelessone.caddy.vHost."shoko.theless.one" = {
        proxy.port = 8111;
        useTailnet = true;
      };

      thelessone.backups.shoko.paths = [ "/var/lib/shoko" ];
    };
}
