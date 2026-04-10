{
  flake.nixosModules.thelessone-transmission =
    {
      pkgs,
      config,
      ...
    }:

    let
      cfg = config.services.transmission;
    in

    {
      sops.secrets.transmission = { };

      sops.templates."transmission-settings.json" = {
        content = builtins.toJSON {
          rpc-password = config.sops.placeholder.transmission;
        };
        restartUnits = [ "transmission.service" ];
        mode = "640";
        owner = cfg.user;
        inherit (cfg) group;
      };

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

      systemd.services.transmission.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.transmission = {
        enable = true;
        openRPCPort = true;
        inherit (config.thelessone.arr) group;
        package = pkgs.transmission_4;

        settings = {
          rpc-enabled = true;
          rpc-port = 58846;
          rpc-whitelist-enabled = true;
          rpc-whitelist = "127.0.0.1,10.0.0.*,100.64.64.*";
          rpc-authentication-required = true;
          rpc-username = "transmission";

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
          blocklist = "https://github.com/Naunter/BT_BlockLists/raw/refs/heads/master/bt_blocklists.gz";
        };

        credentialsFile = config.sops.templates."transmission-settings.json".path;
      };

      services.vopono.allowedTCPPorts = [ config.services.flood.port ];

      systemd.services.flood = {
        requires = [ "transmission.service" ];
        after = [ "transmission.service" ];
      };

      services.flood = {
        enable = true;
        host = "0.0.0.0";
        port = 24325;
      };

      thelessone.caddy.vHost."flood.theless.one" = {
        proxy = { inherit (config.services.flood) port; };
        useVpn = true;
      };

      services.borgbackup.jobs.transmission = {
        repo = "thelessone-borg@10.0.0.6:transmission";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
