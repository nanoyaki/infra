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
    recursiveUpdate
    filterAttrsRecursive
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

          (import ./instance.nix {
            inherit
              lib
              format
              name
              ;
          })
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
        "${iCfg.settings.server.rootDir}/.local/share/Tachidesk" = dirCfg;
        "${iCfg.settings.server.rootDir}/.cache/suwayomi" = dirCfg;
        ${iCfg.settings.server.downloadsPath} = dirCfg;
        ${iCfg.settings.server.localSourcePath} = dirCfg;
      }
    ) cfg.instances;

    systemd.services = mapAttrs' (
      iName: iCfg:
      let
        inherit (iCfg.settings.server) rootDir;
        configFile = format.generate "server.conf" (
          filterAttrsRecursive (_: x: x != null) (
            recursiveUpdate iCfg.settings {
              server = {
                systemTrayEnabled = false;
                initialOpenInBrowserEnabled = false;
              };
            }
          )
        );
      in
      nameValuePair "suwayomi-${iName}" {
        description = "Suwayomi Server instance ${iName}";

        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        environment.JAVA_TOOL_OPTIONS = "-Djava.io.tmpdir=${rootDir}/.cache/suwayomi -Dsuwayomi.tachidesk.config.server.rootDir=${rootDir}";

        script = ''
          ${getExe pkgs.envsubst} -i ${configFile} -o 

          ${getExe cfg.package}
        '';

        serviceConfig = {
          User = "suwayomi";
          Group = "suwayomi";

          Type = "simple";
          Restart = "on-failure";
        };
      }
    ) cfg.instances;
  };
}
