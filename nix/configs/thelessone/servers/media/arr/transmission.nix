{
  flake.nixosModules.thelessone-transmission =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      cfg = config.services.transmission;
    in

    {
      systemd.tmpfiles.settings."10-transmission" = {
        "/mnt/raid/arr-stack/downloads/deluge".d = {
          inherit (cfg) user group;
          mode = "770";
        };

        "/mnt/raid/arr-stack/downloads/deluge/hentai".d = {
          inherit (cfg) user group;
          mode = "770";
        };
      };

      services.vopono.systemd.services.transmission = config.services.transmission.settings.rpc-port;

      systemd.services.transmission = {
        wantedBy = lib.mkForce [ "server-services.target" ];
        environment.TR_SAVE_VERSION_FORMAT = "4";
        unitConfig.RequiresMountsFor = "/mnt/raid";
      };

      services.transmission = {
        enable = true;
        openRPCPort = true;
        inherit (config.thelessone.arr) group;
        package = pkgs.transmission_4;

        settings = {
          rpc-enabled = true;
          rpc-bind-address = "0.0.0.0";
          rpc-port = 9091;
          rpc-host-whitelist-enabled = false;
          rpc-whitelist-enabled = true;
          rpc-whitelist = "127.0.0.1,10.200.1.*";
          rpc-authentication-required = true;
          rpc-username = "transmission";
          rpc-password = "transmission";

          speed-limit-down-enabled = true;
          speed-limit-down = 15000;
          speed-limit-up-enabled = true;
          speed-limit-up = 2500;
          download-queue-enabled = false;
          download-dir = "/mnt/raid/arr-stack/downloads/transmission/complete";
          incomplete-dir-enabled = true;
          incomplete-dir = "/mnt/raid/arr-stack/downloads/transmission/incomplete";

          ratio-limit-enabled = true;
          ratio-limit = 2.0;

          blocklist-enabled = true;
          blocklist-url = "https://github.com/Naunter/BT_BlockLists/raw/refs/heads/master/bt_blocklists.gz";
        };
      };

      services.vopono.allowedTCPPorts = [ config.services.flood.port ];

      systemd.services.flood = {
        wantedBy = lib.mkForce [ "server-services.target" ];
        requires = [ "transmission.service" ];
        after = [ "transmission.service" ];
        serviceConfig.RestrictAddressFamilies = [ "AF_NETLINK" ];
      };

      services.flood = {
        enable = true;
        host = "0.0.0.0";
        port = 24325;
        extraArgs = [
          "--trurl=http://10.200.1.2:${toString cfg.settings.rpc-port}/transmission/rpc"
          "--truser=${cfg.settings.rpc-username}"
          "--trpass=${cfg.settings.rpc-password}"
        ];
      };

      thelessone.caddy.vHost."flood.theless.one" = {
        proxy = {
          inherit (config.services.flood) port;
        };
        useTailnet = true;
      };

      systemd.services.borgbackup-job-transmission.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.transmission = {
        repo = "/mnt/raid/borgbackup/transmission";
        doInit = true;

        paths = cfg.home;

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
    };
}
