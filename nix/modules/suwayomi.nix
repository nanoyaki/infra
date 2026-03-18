{
  flake.nixosModules.suwayomi =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    let
      inherit (lib)
        mkOption
        mkEnableOption
        mkPackageOption
        types
        mkIf
        getExe
        ;

      inherit (lib.attrsets)
        filterAttrs
        nameValuePair
        mapAttrs'
        ;

      inherit (builtins) attrNames;

      cfg = config.services.suwayomi;

      format = pkgs.formats.hocon { };

      dirCfg.d = {
        user = "suwayomi";
        group = "suwayomi";
        mode = "770";
      };
    in

    {
      options.services.suwayomi = {
        enable = mkEnableOption "multiple suwayomi instances";

        package = mkPackageOption pkgs "suwayomi-server" { };

        dataDir = mkOption {
          type = types.path;
          default = "/var/lib/suwayomi";
          example = "/srv/suwayomi";
        };

        instances = mkOption {
          type = types.attrsOf (
            types.submodule (
              { name, ... }:

              {
                options = {
                  # Basepath /var/lib/suwayomi/<instanceName>/
                  enable = mkEnableOption "this instance of suwayomi";

                  user = mkOption {
                    type = types.str;
                    default = "suwayomi-${name}";
                    defaultText = "suwayomi-\${name}";
                    description = "The user to use for the service.";
                  };

                  group = mkOption {
                    type = types.str;
                    default = "suwayomi-${name}";
                    defaultText = "suwayomi-\${name}";
                    description = "The group to use for the service.";
                  };

                  openFirewall = mkOption {
                    type = types.bool;
                    default = false;
                    description = ''
                      Whether to open the firewall for the port in
                      {option}`services.suwayomi.instances.<name>.settings.server.port`.
                    '';
                  };

                  settings = mkOption {
                    type = types.submodule (
                      { config, ... }:

                      {
                        freeformType = format.type;

                        options.server = {
                          ip = mkOption {
                            type = types.str;
                            default = "0.0.0.0";
                            example = "127.0.0.1";
                            description = ''
                              The IP address that Suwayomi will bind to.
                            '';
                          };

                          port = mkOption {
                            type = types.port;
                            default = 8080;
                            example = 4567;
                            description = ''
                              The port that Suwayomi will listen to.
                            '';
                          };

                          downloadAsCbz = mkOption {
                            type = types.bool;
                            default = false;
                            description = ''
                              Download chapters as `.cbz` files.
                            '';
                          };

                          extensionRepos = mkOption {
                            type = types.listOf types.str;
                            default = [ ];
                            example = lib.literalExpression ''
                              [
                                "https://raw.githubusercontent.com/MY_ACCOUNT/MY_REPO/repo/index.min.json"
                              ];
                            '';
                            description = ''
                              URL of repositories from which the extensions can be installed.
                            '';
                          };

                          downloadsPath = mkOption {
                            type = types.path;
                            default = "${config.server.rootDir}/downloads";
                            defaultText = "\${cfg.instances.<name>.settings.rootDir}/downloads";
                            example = "/var/lib/suwayomi/instance/.cache/downloads";
                            description = ''
                              Downloads directory for suwayomi server.
                            '';
                          };

                          rootDir = mkOption {
                            type = types.path;
                            default = "/var/lib/suwayomi/${name}";
                            defaultText = "/var/lib/suwayomi/\${name}";
                            example = "/var/lib/suwayomi/main-instance";
                            description = ''
                              Data directory for suwayomi server.
                            '';
                          };

                          localSourcePath = mkOption {
                            type = types.path;
                            default = "${config.server.rootDir}/local";
                            defaultText = "\${cfg.instances.<name>.settings.rootDir}/local";
                            example = "/var/lib/suwayomi/instance/localManga";
                            description = ''
                              Local manga directory for suwayomi server.
                            '';
                          };

                          systemTrayEnabled = mkOption {
                            type = types.bool;
                            default = false;
                            readOnly = true;
                          };

                          initialOpenInBrowserEnabled = mkOption {
                            type = types.bool;
                            default = false;
                            readOnly = true;
                          };
                        };
                      }
                    );

                    default = { };

                    description = ''
                      Configuration to write to {file}`server.conf`.
                      See <https://github.com/Suwayomi/Suwayomi-Server/wiki/Configuring-Suwayomi-Server> for more information.
                    '';

                    example = lib.literalExpression ''
                      {
                        server.socksProxyEnabled = true;
                        server.socksProxyHost = "yourproxyhost.com";
                        server.socksProxyPort = 8080;
                      };
                    '';
                  };
                };
              }

            )
          );
          default = { };
        };
      };

      config = mkIf (cfg.enable && cfg.instances != { }) {
        networking.firewall.allowedTCPPorts = map (iName: cfg.instances.${iName}.settings.server.port) (
          attrNames (filterAttrs (_: iCfg: iCfg.openFirewall) cfg.instances)
        );

        users.groups.suwayomi = { };

        users.users.suwayomi = {
          group = "suwayomi";
          home = cfg.dataDir;
          description = "Suwayomi Daemon user";
          isSystemUser = true;
        };

        systemd.tmpfiles.settings = mapAttrs' (
          iName: iCfg:
          nameValuePair "10-suwayomi-${iName}" {
            "${iCfg.settings.server.rootDir}/server.conf"."L+" = {
              user = "suwayomi";
              group = "suwayomi";
              mode = "0660";
              argument = (format.generate "server.conf" iCfg.settings).outPath;
            };
            "${iCfg.settings.server.rootDir}/.cache/suwayomi" = dirCfg;
            ${iCfg.settings.server.downloadsPath} = dirCfg;
            ${iCfg.settings.server.localSourcePath} = dirCfg;
          }
        ) cfg.instances;

        systemd.services = mapAttrs' (
          iName: iCfg:

          let
            inherit (iCfg.settings.server) rootDir;
          in

          nameValuePair "suwayomi-${iName}" {
            description = "Suwayomi Server instance ${iName}";

            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];

            environment.JAVA_TOOL_OPTIONS = "-Djava.io.tmpdir=${rootDir}/.cache/suwayomi -Dsuwayomi.tachidesk.config.server.rootDir=${rootDir}";

            serviceConfig = {
              ExecStart = getExe cfg.package;
              Type = "simple";
              Restart = "on-failure";

              # Hardening
              User = "suwayomi";
              Group = "suwayomi";
              CapabilityBoundingSet = "";
              SystemCallFilter = [ "@system-service" ];

              ReadWritePaths = [ rootDir ];
              NoNewPrivileges = true;
              ProtectClock = true;
              RestrictNamespaces = true;
              RestrictSUIDSGID = true;
              LockPersonality = true;
              RestrictRealtime = true;
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_INET6"
              ];
              # java..
              # MemoryDenyWriteExecute = true;
              ProtectHostname = true;

              ProtectSystem = "strict";
              PrivateTmp = true;
              ProtectHome = true;
              PrivateDevices = true;
              ProtectControlGroups = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectKernelLogs = true;
              ProtectProc = "invisible";
            };
          }
        ) cfg.instances;
      };
    };
}
