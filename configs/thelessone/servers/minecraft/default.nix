{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    mkEnableOption
    optionals
    ;
  cfg = config.services.minecraft-servers';

  inherit (lib)
    mapAttrs
    recursiveUpdate
    attrNames
    optionalAttrs
    optionalString
    filter
    mkIf
    ;

  minecraftUUID =
    types.strMatching "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[0-9a-f]{32})"
    // {
      description = "Minecraft UUID";
    };

  inherit (inputs) nix-minecraft nanopkgs;
in

{
  imports = [
    nix-minecraft.nixosModules.minecraft-servers
    ./java.nix
    ./servers
    ./backups.nix
    ./non-nix.nix
  ];

  options.services.minecraft-servers' = {
    openVoicechatPorts = mkEnableOption "" // {
      description = ''
        Whether to open the voice chat ports of the servers
      '';
    };

    serverDefaults = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf types.anything;

        options = {
          appendJvmOpts = mkOption {
            type = types.str;
            default = "";
            description = ''
              JVM options to append to the jvmOpts option
            '';
          };

          packageOverrides = mkOption {
            type = types.attrsOf types.anything;
            default = { };
            description = ''
              Overrides to apply to the server package
            '';
          };

          mods = mkOption {
            type = with types; nullOr (listOf package);
            default = null;
            description = ''
              Mods to install to the server
            '';
            apply = value: if (value == null) then value else pkgs.linkFarmFromDrvs "mods" value;
          };

          datapacks = mkOption {
            type = with types; nullOr (listOf package);
            default = null;
            description = ''
              Datapacks to install to the world of the server
            '';
            apply =
              value:
              if cfg.serverDefaults.gamerules != { } then
                pkgs.linkFarmFromDrvs "datapacks" (
                  (optionals (value != null) value) ++ [ cfg.serverDefaults.gamerules ]
                )
              else if value != null then
                pkgs.linkFarmFromDrvs "datapacks" value
              else
                null;
          };

          gamerules = mkOption {
            type = with types; attrsOf (either bool int);
            default = { };
            description = ''
              Game rules to set on the server
            '';
            apply = gamerules: pkgs.callPackage ./declarative-gamerules.nix { inherit gamerules; };
          };

          bannedPlayers = mkOption {
            type = types.attrsOf minecraftUUID;
            default = { };
            description = ''
              Player names mapped to minecraft UUIDs
            '';
          };
        };
      };
      default = { };
    };

    servers = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, ... }:

          {
            freeformType = types.attrsOf types.anything;

            options = {
              useDefaults = mkEnableOption "" // {
                default = true;
                description = ''
                  Whether to use the default minecraft server options
                '';
              };

              appendJvmOpts = mkOption {
                type = types.str;
                default = if config.useDefaults then cfg.serverDefaults.appendJvmOpts else "";
                description = ''
                  JVM options to append to the jvmOpts option
                '';
              };

              packageOverrides = mkOption {
                type = types.attrsOf types.anything;
                default = if config.useDefaults then cfg.serverDefaults.packageOverrides else { };
                description = ''
                  Overrides to apply to the server package
                '';
              };

              mods = mkOption {
                type = with types; nullOr (listOf package);
                default = if config.useDefaults then cfg.serverDefaults.mods else null;
                description = ''
                  Mods to install to the server
                '';
                apply = value: if (value == null) then value else pkgs.linkFarmFromDrvs "mods" value;
              };

              datapacks = mkOption {
                type = with types; nullOr (listOf package);
                default = if config.useDefaults then cfg.serverDefaults.datapacks else null;
                description = ''
                  Datapacks to install to the world of the server
                '';
                apply =
                  value:
                  if config.gamerules != { } then
                    pkgs.linkFarmFromDrvs "datapacks" ((optionals (value != null) value) ++ [ config.gamerules ])
                  else if value != null then
                    pkgs.linkFarmFromDrvs "datapacks" value
                  else
                    null;
              };

              gamerules = mkOption {
                type = with types; attrsOf (either bool int);
                default = if config.useDefaults then cfg.serverDefaults.gamerules else { };
                description = ''
                  Game rules to set on the server
                '';
                apply = gamerules: pkgs.callPackage ./declarative-gamerules.nix { inherit gamerules; };
              };

              bannedPlayers = mkOption {
                type = types.attrsOf minecraftUUID;
                default = if config.useDefaults then cfg.serverDefaults.bannedPlayers else { };
                description = ''
                  Player names mapped to minecraft UUIDs
                '';
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = {
    # BUG: No idea why the overlay order is so
    # messed up. Had to import nanopkgs here again
    nixpkgs.overlays = [
      nanopkgs.overlays.default
      nix-minecraft.overlay
    ];

    services.minecraft-servers.servers = mapAttrs (
      _: srvCfg:
      let
        defaults = optionalAttrs srvCfg.useDefaults cfg.serverDefaults;
        overrides = removeAttrs (recursiveUpdate defaults srvCfg) [
          "useDefaults"
          "appendJvmOpts"
          "mods"
          "datapacks"
          "gamerules"
          "packageOverrides"
          "bannedPlayers"
        ];

        worldName = overrides.serverProperties.level-name or "world";
        addOptions = {
          jvmOpts =
            (srvCfg.jvmOpts or "") + " ${optionalString (srvCfg.appendJvmOpts != "") srvCfg.appendJvmOpts}";
          symlinks = optionalAttrs (srvCfg.mods != null) { inherit (srvCfg) mods; };
          files =
            (optionalAttrs (srvCfg.datapacks != null) { "${worldName}/datapacks" = srvCfg.datapacks; })
            // optionalAttrs (srvCfg.bannedPlayers != { }) {
              "banned-players.json" = {
                format = pkgs.formats.json { };
                value = map (name: {
                  inherit name;
                  uuid = srvCfg.bannedPlayers.${name};
                  created = "1970-01-01 00:00:01 +0000";
                  source = "server";
                  expires = "forever";
                }) (attrNames srvCfg.bannedPlayers);
              };
            };
        }
        // lib.optionalAttrs (srvCfg ? package) {
          package = srvCfg.package.override srvCfg.packageOverrides;
        };

        finalCfg = recursiveUpdate overrides addOptions;
      in
      finalCfg
    ) cfg.servers;

    # Open voicechat ports
    networking.firewall.allowedUDPPorts = mkIf cfg.openVoicechatPorts (
      map
        (server: cfg.servers.${server}.symlinks."config/voicechat/voicechat-server.properties".value.port)
        (
          filter (server: cfg.servers ? ${server}.symlinks."config/voicechat/voicechat-server.properties") (
            attrNames cfg.servers
          )
        )
    );
  };
}
