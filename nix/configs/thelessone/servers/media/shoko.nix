{
  flake.nixosModules.thelessone-shoko =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib) mkForce;
      inherit (config) prt dmn;
    in

    {
      # Can't be changed declaratively in versions before 6.0.0
      prt.shoko = mkForce 8111;
      dmn.shoko = "shoko.theless.one";

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

      systemd.services.shoko = {
        wantedBy = mkForce [ "server-services.target" ];
        unitConfig.RequiresMountsFor = "/mnt/raid";
        serviceConfig = {
          DynamicUser = mkForce false;
          User = "shoko";
          Group = config.thelessone.arr.group;
        };
      };

      thelessone.caddy.vHost.${dmn.shoko} = {
        proxy.port = prt.shoko;
        useTailnet = true;
      };

      thelessone.backups.shoko.paths = [ "/var/lib/shoko" ];
    };
}
