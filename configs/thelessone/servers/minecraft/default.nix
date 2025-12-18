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

  additionalOptions = types.submodule (
    { config, ... }:

    {
      freeformType = types.attrsOf types.anything;

      options = {
        enableDefaults = mkEnableOption "" // {
          default = true;
          description = ''
            Whether to use the default minecraft server options
          '';
        };

        appendJvmOpts = mkOption {
          type = types.str;
          default = "";
          description = ''
            JVM options to append to the jvmOpts option
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
            value: pkgs.linkFarmFromDrvs "datapacks" ((optionals (value != null) value) ++ config.gamerules);
        };

        gamerules = mkOption {
          type = with types; attrsOf (either bool int);
          default = { };
          description = ''
            Game rules to set on the server
          '';
          apply = gamerules: pkgs.callPackage ./declarative-gamerules.nix { inherit gamerules; };
        };
      };
    }
  );

  inherit (lib)
    mapAttrs
    recursiveUpdate
    removeAttrs
    attrNames
    optionalAttrs
    optionalString
    filter
    mkIf
    ;

  inherit (inputs) nix-minecraft nanopkgs;
in

{
  imports = [
    nix-minecraft.nixosModules.minecraft-servers
    ./java.nix
    ./servers
    ./backups.nix
  ];

  options.services.minecraft-servers' = {
    openVoicechatPorts = mkEnableOption "" // {
      description = ''
        Whether to open the voice chat ports of the servers
      '';
    };

    serverDefaults = mkOption {
      type = additionalOptions;
      default = { };
      description = ''
        Defaults for the minecraft servers
      '';
    };

    servers = mkOption {
      type = types.attrsOf additionalOptions;
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
        defaults = optionalAttrs srvCfg.enableDefaults cfg.serverDefaults;
        overrides = removeAttrs srvCfg (attrNames (additionalOptions.getSubOptions additionalOptions));
        overridenCfg = recursiveUpdate defaults overrides;

        worldName = overridenCfg.serverProperties.level-name or "world";
        addOptions = {
          jvmOpts = srvCfg.jvmOpts + " ${optionalString (srvCfg.appendJvmOpts != "") srvCfg.appendJvmOpts}";
          symlinks = optionalAttrs (srvCfg.mods != null) { inherit (srvCfg) mods; };
          files = optionalAttrs (srvCfg.datapacks != null) { "${worldName}/datapacks" = srvCfg.datapacks; };
        };

        finalCfg = recursiveUpdate overridenCfg addOptions;
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
