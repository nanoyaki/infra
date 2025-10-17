{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) mkOption types getExe;

  domain = "https://flood.theless.one";
  cfg = config.services.deluge;

  configDir = "${cfg.dataDir}/.config/deluge";
in

{
  options.services.deluge.plugins.label = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          apply_max = mkOption {
            type = types.bool;
            default = false;
          };

          max_download_speed = mkOption {
            type = types.int;
            default = -1;
          };

          max_upload_speed = mkOption {
            type = types.int;
            default = -1;
          };

          max_connections = mkOption {
            type = types.int;
            default = -1;
          };

          max_upload_slots = mkOption {
            type = types.int;
            default = -1;
          };

          prioritize_first_last = mkOption {
            type = types.bool;
            default = false;
          };

          apply_queue = mkOption {
            type = types.bool;
            default = false;
          };

          is_auto_managed = mkOption {
            type = types.bool;
            default = false;
          };

          stop_at_ratio = mkOption {
            type = types.bool;
            default = false;
          };

          stop_ratio = mkOption {
            type = types.float;
            default = 2.0;
          };

          remove_at_ratio = mkOption {
            type = types.bool;
            default = false;
          };

          apply_move_completed = mkOption {
            type = types.bool;
            default = false;
          };

          move_completed = mkOption {
            type = types.bool;
            default = false;
          };

          move_completed_path = mkOption {
            type = with types; either (strMatching ''^$'') path;
            default = "";
          };

          auto_add = mkOption {
            type = types.bool;
            default = false;
          };

          auto_add_trackers = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
        };
      }
    );
    default = { };
    description = ''

    '';
  };

  config = {
    sops.secrets = {
      "deluge/localclient" = { };
      "deluge/nanoyaki" = { };
      "deluge/sonarr" = { };
      "deluge/radarr" = { };
      "deluge/prowlarr" = { };
    };

    sops.templates.deluge-auth = {
      content = ''
        localclient:${config.sops.placeholder."deluge/localclient"}:10
        nanoyaki:${config.sops.placeholder."deluge/nanoyaki"}:10
        sonarr:${config.sops.placeholder."deluge/sonarr"}:5
        radarr:${config.sops.placeholder."deluge/radarr"}:5
        prowlarr:${config.sops.placeholder."deluge/prowlarr"}:5
      '';
      restartUnits = [ "deluged.service" ];
      mode = "640";
      owner = cfg.user;
      inherit (cfg) group;
    };

    systemd.tmpfiles.settings."10-deluged" = {
      "/mnt/raid/arr-stack/downloads/deluge".d = {
        inherit (cfg) user group;
        mode = "770";
      };

      "/mnt/raid/arr-stack/downloads/deluge/hentai".d = {
        inherit (cfg) user group;
        mode = "770";
      };
    };

    services.vopono.systemd.services.deluged = cfg.config.daemon_port;

    systemd.services.deluged.serviceConfig.ExecStartPre = getExe (
      pkgs.writeShellApplication {
        name = "mutate-deluge-label-config";
        runtimeInputs = with pkgs; [ jq ];
        text = ''
          config_file="${configDir}/label.conf"

          if [[ ! -f "$config_file" ]] || ! jq -e '.labels?' "$config_file" > /dev/null
          then
            echo '{ "torrent_labels": { }, "labels": { } }' > "$config_file"
          fi

          config="$(jq -sr '.[(. | length) - 1]' "$config_file")"
          jq -n \
            --argjson config '${builtins.toJSON cfg.plugins.label}' \
            '
              def recursiveUpdate(original; updater):
                reduce (updater | keys_unsorted[]) as $key
                (
                  original;
                  if .[$key]? and (.[$key] | type) == "object" and (updater[$key] | type) == "object"
                  then .[$key] = recursiveUpdate(.[$key]; updater[$key])
                  else .[$key] = updater[$key]
                  end
                );

              .labels = recursiveUpdate(.labels; $config) | .
            ' <<< "$config" > "$config_file"
        '';
      }
    );

    systemd.services.deluged.unitConfig.RequiresMountsFor = "/mnt/raid";
    services.deluge = {
      declarative = true;
      enable = true;
      web.enable = true;
      inherit (config.arr) group;

      openFirewall = true;

      config = {
        # This setting is mean
        auto_managed = false;
        super_seeding = true;

        max_active_downloading = 1500;
        max_active_seeding = 1500;
        max_active_limit = 1500;

        max_download_speed = 15000.0;
        max_upload_speed = 2500.0;
        share_ratio_limit = 2.0;
        stop_seed_at_ratio = 2.0;
        allow_remote = true;
        daemon_port = 58846;
        listen_ports = [
          6881
          6891
        ];
        download_location = "/mnt/raid/arr-stack/downloads/transmission/incomplete";
        move_completed = true;
        move_completed_path = "/mnt/raid/arr-stack/downloads/transmission/complete";
        pre_allocate_storage = true;
        enabled_plugins = [ "Label" ];
      };

      plugins.label.hentai = {
        remove_at_ratio = true;
        stop_ratio = 2.0;
        apply_move_completed = true;
        move_completed = true;
        move_completed_path = "/mnt/raid/arr-stack/downloads/deluge/hentai";
      };

      authFile = config.sops.templates.deluge-auth.path;
    };

    services.vopono.allowedTCPPorts = [ config.services.flood.port ];

    systemd.services.flood = {
      requires = [ "deluged.service" ];
      after = [ "deluged.service" ];
    };

    services.flood = {
      enable = true;
      host = "0.0.0.0";
      port = 24325;
      package = pkgs.flood.overrideAttrs (prevAttrs: {
        patches = (prevAttrs.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/AllySummers/flood-deluge/commit/50b3aa96bc97200678a00e92252e8b10cb821360.patch";
            hash = "sha256-B9bqWTfxDsGSSZsZ/wXQ07e8nTsPjBxKj6KIYPkkkYI=";
          })
        ];
      });
    };

    config'.caddy.vHost.${domain} = {
      proxy = { inherit (config.services.flood) port; };
      useMtls = true;
    };

    config'.homepage.categories."Services".services.Flood = {
      icon = "flood.svg";
      href = domain;
      siteMonitor = domain;
      description = "WebUI for torrenting clients";
    };
  };
}
