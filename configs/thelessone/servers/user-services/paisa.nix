{ config, ... }:

let
  cfg = config.services.paisa;
in

{
  services.paisa = {
    enable = true;
    openFirewall = true;
    settings = {
      locale = "de-DE";
      time_zone = "Europe/Berlin";
      week_starting_day = 1;
    };
  };

  systemd.services.paisa.environment = {
    XDG_CACHE_HOME = "${cfg.settings.dataDir}/.cache";
    HOME = cfg.settings.dataDir;
  };

  config'.caddy.vHost."finances.theless.one" = {
    proxy = { inherit (cfg) port; };
    useVpn = true;
  };
}
