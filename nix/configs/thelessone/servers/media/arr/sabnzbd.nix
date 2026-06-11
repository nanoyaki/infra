{
  flake.nixosModules.thelessone-sabnzbd =
    { lib, config, ... }:

    let
      inherit (config)
        prt
        dmn
        plh
        tpl
        ;
    in

    {
      prt.sabnzbd = 8021;
      dmn.sabnzbd = "sabnzbd.theless.one";

      sec = {
        "sabnzbd/api-key" = { };
        "sabnzbd/nzb-key" = { };

        "sabnzbd/username" = { };
        "sabnzbd/password" = { };

        "sabnzbd/eweka-username" = { };
        "sabnzbd/eweka-password" = { };
      };

      tpl."secrets.ini" = {
        content = ''
          [misc]
          username = ${plh."sabnzbd/username"}
          password = ${plh."sabnzbd/password"}

          api_key = ${plh."sabnzbd/api-key"}
          nzb_key = ${plh."sabnzbd/nzb-key"}

          [servers]
          [[news.eweka.nl]]
          username = ${plh."sabnzbd/eweka-username"}
          password = ${plh."sabnzbd/eweka-password"}
        '';

        owner = config.services.sabnzbd.user;
      };

      services.vopono.allowedTCPPorts = [ prt.sabnzbd ];

      systemd.services.sabnzbd.wantedBy = lib.mkForce [ "server-services.target" ];
      services.sabnzbd = {
        enable = true;
        inherit (config.thelessone.arr) group;
        configFile = null;

        allowConfigWrite = false;
        secretFiles = [ tpl."secrets.ini".path ];
        settings = {
          misc = {
            # Webinterface
            web_color = "Night";
            refresh_rate = 1;

            # Proxy
            host = "127.0.0.1";
            inet_exposure = 4;
            port = prt.sabnzbd;
            host_whitelist = dmn.sabnzbd;
            verify_xff_header = 1;
            # LAN and VPN
            local_ranges = "10.0.0.0/24, 100.64.64.0/24";

            # Settings where i don't
            # know what they do
            sorters_converted = 1;
            direct_unpack_tested = 1;

            # Files
            permissions = 2770;
            download_dir = "${config.thelessone.arr.home}/downloads/incomplete";
            complete_dir = "${config.thelessone.arr.home}/downloads/complete";
            no_dupes = 4;
            direct_unpack = 1;
            history_retention_number = 1;
            check_new_rel = 1;

            # Limits
            cache_limit = "1G";
            bandwidth_max = "10M";
            bandwidth_perc = 100;

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
            port = prt.nntps;
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

                shoko.order = 6;
                shoko.dir = "${config.thelessone.arr.home}/downloads/shoko";

                beets.order = 7;
                beets.dir = "${config.thelessone.arr.home}/downloads/beets";
              };
        };
      };

      thelessone.caddy.vHost.${dmn.sabnzbd} = {
        proxy.port = prt.sabnzbd;
        useTailnet = true;
      };

      thelessone.backups.sabnzbd.paths = [ "/var/lib/sabnzbd" ];
    };
}
