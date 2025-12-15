{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.services.paisa;
in

{
  services.paisa = {
    enable = true;
    openFirewall = true;
    settings = {
      ledger_cli = "hledger";
      locale = "de-DE";
      time_zone = "Europe/Berlin";
      week_starting_day = 1;
    };
  };

  systemd.services.paisa = {
    path = [ pkgs.hledger ];

    environment = {
      XDG_CACHE_HOME = "${cfg.settings.dataDir}.cache";
      HOME = cfg.settings.dataDir;
    };
  };

  users.users.paisa = {
    isSystemUser = true;
    home = cfg.settings.dataDir;
    group = config.users.groups.paisa.name;
  };

  users.groups.paisa = { };

  systemd.services.paisa.serviceConfig = {
    User = "paisa";
    Group = "paisa";
    DynamicUser = lib.mkForce false;
  };

  config'.caddy.vHost."finances.theless.one" = {
    proxy = { inherit (cfg) port; };
    useVpn = true;
  };
}
