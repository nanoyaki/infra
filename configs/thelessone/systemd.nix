_:

# i really have to learn more about systemd...

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
}
