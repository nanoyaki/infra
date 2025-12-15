{ config, ... }:

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

  config'.caddy.vHost."finances.theless.one" = {
    proxy = { inherit (config.services.paisa) port; };
    useVpn = true;
  };
}
