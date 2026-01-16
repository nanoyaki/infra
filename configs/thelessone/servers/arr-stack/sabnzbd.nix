{ lib, config, ... }:

let
  domain = "sabnzbd.theless.one";
in

{
  sops.secrets = {
    "sabnzbd/api-key" = { };
    "sabnzbd/nzb-key" = { };

    "sabnzbd/username" = { };
    "sabnzbd/password" = { };

    "sabnzbd/eweka-username" = { };
    "sabnzbd/eweka-password" = { };
  };

  sops.templates."secrets.ini".content = ''
    [misc]
    username = ${config.sops.placeholder."sabnzbd/username"}
    password = ${config.sops.placeholder."sabnzbd/password"}

    api_key = ${config.sops.placeholder."sabnzbd/api-key"}
    nzb_key = ${config.sops.placeholder."sabnzbd/nzb-key"}

    [servers]
    [[news.eweka.nl]]
    username = ${config.sops.placeholder."sabnzbd/eweka-username"}
    password = ${config.sops.placeholder."sabnzbd/eweka-password"}
  '';

  services.vopono.allowedTCPPorts = [ 8080 ];

  systemd.services.sabnzbd.unitConfig.RequiresMountsFor = "/mnt/raid";
  services.sabnzbd = {
    enable = true;
    inherit (config.arr) group;

    allowConfigWrite = false;
    secretFiles = [ config.sops.templates."secrets.ini".path ];
    settings = {
      misc = {
        # Webinterface
        web_color = "Night";
        refresh_rate = 1;

        # Proxy
        host = "127.0.0.1";
        inet_exposure = 4;
        port = 8080;
        host_whitelist = "sabnzbd.theless.one";
        verify_xff_header = 1;
        # LAN and VPN
        local_ranges = "10.0.0.0/24, 100.64.64.0/24";

        # Settings where i don't
        # know what they do
        sorters_converted = 1;
        direct_unpack_tested = 1;

        # Files
        permissions = 2770;
        download_dir = "${config.arr.home}/downloads/incomplete";
        complete_dir = "${config.arr.home}/downloads/complete";
        no_dupes = 4;
        direct_unpack = 1;
        history_retention_number = 1;
        check_new_rel = 1;

        # Keep the disk usable
        complete_free = "100G";
        fulldisk_autoresume = 1;
      };

      logging.log_level = 2;

      servers."news.eweka.nl" = {
        enable = true;
        required = true;

        displayname = "Eweka";
        name = "news.eweka.nl";
        host = "news.eweka.nl";
        port = 563;
        timeout = 60;
        connections = 50;
        ssl = true;
        ssl_verify = 3;

        expire_date = "2026-06-06";
      };

      categories =
        lib.mapAttrs
          (
            name: overrides:
            {
              inherit name;
              pp = "";
              script = "Default";
              dir = "";
              newzbin = "";
              priority = -100;
            }
            // overrides
          )
          {
            "*" = {
              order = 0;
              pp = 3;
              script = "None";
              priority = 0;
            };

            sonarr.order = 1;
            radarr.order = 2;
            prowlarr.order = 3;
            direct-prowlarr.order = 4;
            whisparr.order = 5;

            shoko.order = 6;
            shoko.dir = "${config.arr.home}/downloads/shoko";

            beets.order = 7;
            beets.dir = "${config.arr.home}/downloads/beets";
          };
    };
  };

  config'.caddy.vHost.${domain} = {
    proxy = { inherit (config.services.sabnzbd.settings.misc) port; };
    useVpn = true;
  };

  services.borgbackup.jobs.sabnzbd = {
    repo = "thelessone-borg@10.0.0.6:sabnzbd";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var/lib/sabnzbd";

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
