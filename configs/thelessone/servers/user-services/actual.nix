{ config, ... }:

let
  cfg = config.services.actual;
in

{
  services.actual = {
    enable = true;
    openFirewall = true;
    settings.port = 7500;
  };

  config'.caddy.vHost."finances.theless.one" = {
    proxy = { inherit (cfg.settings) port; };
    useVpn = true;
  };
}
