{ config, ... }:

let
  inherit (config) arr;

  domain = "bazarr.theless.one";
in

{
  services.bazarr = {
    enable = true;
    inherit (arr) group;
  };

  config'.caddy.vHost.${domain} = {
    proxy.port = config.services.bazarr.listenPort;
    useVpn = true;
  };

  services.borgbackup.jobs.bazarr = {
    repo = "thelessone-borg@10.0.0.6:bazarr";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var/lib/bazarr";

    encryption.mode = "none";
    compression = "zstd";

    startAt = "daily";
    persistentTimer = true;
    prune.keep = {
      within = "1d";
      daily = 14;
      weekly = 12;
      monthly = -1;
    };
  };
}
