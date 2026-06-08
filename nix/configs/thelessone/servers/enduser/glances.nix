{
  flake.nixosModules.thelessone-glances =
    { config, ... }:

    {
      services.glances.enable = true;
      thelessone.caddy.vHost."glances.theless.one" = {
        proxy = { inherit (config.services.glances) port; };
        useTailnet = true;
      };
    };
}
