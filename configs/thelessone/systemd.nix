_:

# lib.filterAttrs (_: cfg: cfg ? serviceConfig.Type && cfg.serviceConfig.Type != "oneshot" || (!(cfg ? serviceConfig.Type))) config.systemd.services

{
  systemd.services.rspamd = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  systemd.services.caddy = {
    wants = [
      "network-online.target"
      "copyparty.service"
    ];
    after = [
      "network-online.target"
      "copyparty.service"
    ];
  };

  systemd.services.copyparty = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  services.rspamd.enable = true;
}
