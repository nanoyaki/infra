{
  flake.nixosModules.thelessone-actual =
    { lib, config, ... }:

    let
      cfg = config.services.actual;
    in

    {
      systemd.services.actual.wantedBy = lib.mkForce [ "server-services.target" ];
      services.actual = {
        enable = true;
        openFirewall = true;
        settings.port = 7500;
      };

      thelessone.caddy.vHost."finances.theless.one" = {
        proxy = { inherit (cfg.settings) port; };
        useTailnet = true;
      };

      thelessone.backups.actual.paths = [ "/var/lib/private/actual" ];
    };
}
