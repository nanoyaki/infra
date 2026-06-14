{
  flake.nixosModules.thelessone-actual =
    { lib, config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.actual = 8003;
      dmn.finances = "finances.theless.one";

      systemd.services.actual.wantedBy = lib.mkForce [ "server-services.target" ];
      services.actual = {
        enable = true;
        openFirewall = true;
        settings.port = prt.actual;
      };

      thelessone.caddy.vHost.${dmn.finances} = {
        proxy.port = prt.actual;
        useTailnet = true;
      };

      thelessone.backups.actual.paths = [ "/var/lib/private/actual" ];
    };
}
