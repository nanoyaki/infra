{
  flake.nixosModules.thelessone-glances =
    { config, ... }:

    let
      inherit (config) prt dmn;
    in

    {
      prt.glances = 8024;
      dmn.glances = "glances.theless.one";

      services.glances.enable = true;
      services.glances.port = prt.glances;

      thelessone.caddy.vHost.${dmn.glances} = {
        proxy.port = prt.glances;
        useTailnet = true;
      };
    };
}
