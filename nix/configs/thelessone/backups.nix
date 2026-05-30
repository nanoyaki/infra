{
  flake.nixosModules.thelessone-backups =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib)
        mkOption
        types
        mapAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        getExe
        ;

      cfg = config.thelessone.backups;
      format = pkgs.formats.toml { };

      mkBackupConfig =
        name: backup:

        (removeAttrs backup [
          "snapshot"
          "paths"
          "exclude"
          "timerConfig"
          "command"
        ])
        // {
          global = {
            check-index = true;
          }
          // (backup.global or { });

          repository = {
            repository = "/mnt/raid/backup.d/${name}";
            password-file = config.sops.secrets.restic-encryption.path;
            no-cache = true; # unnecessary for local repos
          }
          // (backup.repository or { });

          backup.snapshots = [
            (
              (backup.snapshot or { })
              // (optionalAttrs (backup.paths != [ ]) {
                sources = backup.paths;
                globs = map (path: "!${path}") backup.exclude;
              })
              // (optionalAttrs (backup.command != "") {
                inherit name;
                sources = [ "-" ];
                stdin-command = backup.command;
                as-path = name;
              })
            )
          ];

          forget = {
            keep-within-daily = "7 days";
            keep-weekly = 4;
            keep-monthly = 3;
            keep-yearly = 1;
          }
          // (backup.forget or { });
        };

      mkBackupTimer =
        name: backup:

        nameValuePair "restic-backup-${name}" {
          inherit (backup) timerConfig;
          wantedBy = [ "timers.target" ];
        };

      mkBackupService =
        name: _:

        let
          profileName = "rustic-backup-${name}";
        in

        nameValuePair profileName {
          requires = [ "mnt-raid.mount" ];
          after = [ "mnt-raid.mount" ];

          preStart = ''
            [[ ! -d ${configs.${name}.repository.repository} ]] && ${getExe pkgs.rustic} init -P ${profileName}
          '';

          serviceConfig = {
            ExecStart = "${getExe pkgs.rustic} backup -P ${profileName}";
            ExecStopPost = "${getExe pkgs.rustic} forget -P ${profileName}";
            Type = "oneshot";
            Restart = "no";

            WorkingDirectory = configDir;
            StateDirectory = "rustic";

            CapabilityBoundingSet = [ "" ];
            DeviceAllow = [ "" ];
            LockPersonality = true;
            PrivateDevices = true;
            PrivateTmp = true;
            PrivateUsers = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
            UMask = "0077";
          };
        };

      configs = mapAttrs mkBackupConfig cfg;
      configFiles = mapAttrs (name: _: format.generate "rustic-backup-${name}.toml" configs.${name}) cfg;
      configDir = pkgs.linkFarmFromDrvs "rustic-config.d" (builtins.attrValues configFiles);
    in

    {
      options.thelessone.backups = mkOption {
        type = types.attrsOf (
          types.submodule {
            freeformType = format.type;

            options = {
              paths = mkOption {
                type = types.listOf types.path;
                default = [ ];
              };

              exclude = mkOption {
                type = types.listOf types.path;
                default = [ ];
              };

              command = mkOption {
                type = types.str;
                default = "";
              };

              timerConfig = mkOption {
                type = types.attrsOf types.anything;
                default = {
                  OnCalendar = "daily";
                  Persistent = true;
                  RandomizedDelaySec = "30min";
                };
              };
            };
          }
        );
        default = { };
      };

      config = {
        assertions = [
          {
            assertion =
              cfg != { }
              -> lib.all (
                backup:
                (backup.paths != [ ] && backup.command == "") || (backup.paths == [ ] && backup.command != "")
              ) (builtins.attrValues cfg);
            message = ''
              At least one backup path or command must be specified in config.thelessone.backups.<name>.paths
            '';
          }
        ];

        sops.secrets.restic-encryption = { };

        environment.systemPackages = map (
          name:

          let
            wrapperName = "rustic-backup-${name}";
          in

          pkgs.symlinkJoin {
            pname = wrapperName;
            inherit (pkgs.rustic) version;
            paths = [ pkgs.rustic ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              makeWrapper $out/bin/rustic $out/bin/${wrapperName} \
                --add-flags '-P' \
                --add-flags '${wrapperName}' \
                --chdir "${configDir}"
            '';

            meta.mainProgram = wrapperName;
          }
        ) (builtins.attrNames cfg);

        systemd.services = mapAttrs' mkBackupService cfg;
        systemd.timers = mapAttrs' mkBackupTimer cfg;
      };
    };
}
