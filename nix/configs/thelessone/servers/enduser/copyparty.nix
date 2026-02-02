{ inputs, ... }:

{
  flake.nixosModules.thelessone-copyparty =
    {
      lib,
      config,
      ...
    }:

    let
      inherit (lib)
        nameValuePair
        mapAttrs'
        toLower
        attrNames
        filter
        hasPrefix
        listToAttrs
        ;
      cfg = config.services.copyparty;

      defaults.flags = {
        fka = 32;
        dks = true;
      };

      backupPath = "/mnt/raid";
    in

    {
      imports = [ inputs.copyparty.nixosModules.default ];
      nixpkgs.overlays = [ inputs.copyparty.overlays.default ];

      sops.secrets = listToAttrs (
        map
          (
            user:
            nameValuePair "copyparty/${user}" {
              owner = cfg.user;
              restartUnits = [ "copyparty.service" ];
            }
          )
          [
            "hana"
            "sebi"
            "thomas"
            "ashley"
            "nik"
          ]
      );

      services.copyparty = {
        enable = true;
        mkHashWrapper = true;

        settings = {
          # Server options
          i = "unix:770:${cfg.group}:/run/copyparty/copyparty.sock";
          hist = "/var/cache/copyparty";
          shr = "/share";
          no-reload = true;
          name = "Theless.one files";
          theme = 0;

          # Password options
          chpw = true;
          ah-alg = "argon2";

          # Media options
          allow-flac = true;

          # Global options
          hardlink-only = true;
          magic = true;
          e2dsa = true;
          e2vp = true;
          df = "100g";
          xdev = true;
          xvol = true;
          grid = true;
          no-dot-ren = true;
          no-robots = true;
          force-js = true;
          og-ua = "Discordbot";
          fk = 24;
          dk = 48;
          chmod-f = "640";
          chmod-d = "750";
          ban-pw = "5,60,1440";
          grp-all = "acct";
          no-dupe = true;
          # usernames = true;
        };

        accounts = listToAttrs (
          map (
            attr:
            let
              rawUser = lib.removePrefix "copyparty/" attr;
              user =
                (lib.toUpper (lib.substring 0 1 rawUser)) + (lib.substring 1 (lib.stringLength rawUser) rawUser);
            in
            nameValuePair user {
              # FIXME: Passwords are broken due to reinstall
              passwordFile = config.sops.secrets.${attr}.path;
            }
          ) (filter (attr: hasPrefix "copyparty/" attr) (attrNames config.sops.secrets))
        );

        volumes = {
          "/" = {
            path = "/mnt/raid/copyparty/root";
            access = {
              r = "@acct";
              A = "Hana";
            };
            inherit (defaults) flags;
          };

          "/shared" = {
            path = "/mnt/raid/copyparty/shared";
            access = {
              "rwmd." = "@acct";
              A = [
                "Hana"
                "Thomas"
              ];
            };
            inherit (defaults) flags;
          };

          "/shared-public-download" = {
            path = "/mnt/raid/copyparty/public";
            access = {
              "rwmd." = "@acct";
              A = [
                "Hana"
                "Thomas"
              ];
              g = "*";
            };
          };
        }
        // mapAttrs' (
          user: _:
          nameValuePair "/${toLower user}" {
            path = "/mnt/raid/copyparty-priv/${user}";
            access.A = user;
            inherit (defaults) flags;
          }
        ) cfg.accounts;
      };

      systemd.services.copyparty = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        unitConfig.RequiresMountsFor = "/mnt/raid";
        serviceConfig.RuntimeDirectoryMode = lib.mkForce "0770";
      };

      systemd.services.caddy.serviceConfig.BindPaths = [ "/run/copyparty/copyparty.sock" ];
      users.users.${config.services.caddy.user}.extraGroups = [ cfg.group ];
      thelessone.caddy.vHost."files.theless.one".extraConfig = ''
        reverse_proxy unix//run/copyparty/copyparty.sock
      '';

      services.borgbackup.jobs.copyparty = {
        repo = "thelessone-borg@10.0.0.6:copyparty";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
        doInit = true;

        paths = backupPath;
        patterns = [
          "+ ${backupPath}/copyparty"
          "+ ${backupPath}/copyparty-priv"
          "- **"
        ];

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
