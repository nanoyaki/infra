{ withSystem, inputs, ... }:

{
  flake.nixosModules.thelessone-minecraft =
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
    in

    {
      imports = [
        inputs.nix-minecraft.nixosModules.minecraft-servers
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
                apply = gamerules: pkgs.declarative-gamerules.override { inherit gamerules; };
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
                    apply = gamerules: pkgs.declarative-gamerules.override { inherit gamerules; };
                  };
                };
              }
            )
          );
          default = { };
        };
      };

      config = {
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
            ];

            worldName = overrides.serverProperties.level-name or "world";
            addOptions = {
              jvmOpts =
                (srvCfg.jvmOpts or "") + " ${optionalString (srvCfg.appendJvmOpts != "") srvCfg.appendJvmOpts}";
              symlinks = optionalAttrs (srvCfg.mods != null) { inherit (srvCfg) mods; };
              files = optionalAttrs (srvCfg.datapacks != null) { "${worldName}/datapacks" = srvCfg.datapacks; };
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
    };

  perSystem =
    {
      inputs',
      pkgs,
      config,
      ...
    }:

    {
      packages = {
        thelessone-minecraft-logomark =
          pkgs.runCommand "thelessone-minecraft-logomark"
            {
              env.logomarkSvg = pkgs.fetchurl {
                url = "https://git.theless.one/marumarukyun/Theless.one-branding/raw/commit/5f39d64a4070648449fad4c385b9532939cd36e6/svg/thelessone-filled-rainbow.svg";
                hash = "sha256-4QUo+nY8JOP5UGR9h/oQBCQH0AH5FO6a77FJZ+tyPlw=";
              };
              nativeBuildInputs = [ pkgs.imagemagick ];
            }
            ''
              mkdir -p $out
              magick \
                -background none \
                $logomarkSvg \
                -trim \
                -resize 64x64 \
                -gravity center \
                -extent 64x64 \
                $out/icon.png
            '';

        nix-minecraft-logomark =
          pkgs.runCommand "nix-minecraft-logomark"
            {
              env.logomarkSvg =
                inputs'.nixos-branding.legacyPackages.nixos-branding.artifacts.media-kit.nixos-logomark-rainbow-gradient-recommended;
              nativeBuildInputs = [ pkgs.imagemagick ];
            }
            ''
              mkdir -p $out
              magick \
                -background none \
                $logomarkSvg/nixos-logomark-rainbow-gradient-recommended.svg \
                -trim \
                -resize 64x64 \
                -gravity center \
                -extent 64x64 \
                $out/icon.png
            '';

        declarative-gamerules = pkgs.callPackage (
          {
            lib,
            stdenvNoCC,
            runCommand,
            writeText,
            jq,
            gamerules ? { },
          }:

          let
            inherit (lib)
              concatStringsSep
              attrNames
              isBool
              mapAttrs
              ;

            toValidString =
              actual: if isBool actual then (if actual then "true" else "false") else toString actual;

            toGamerule =
              rawGamerule:
              let
                # Support 1.21.11 and older
                minecraftPrefix = lib.optionalString (
                  (!lib.hasInfix ":" rawGamerule)
                  && lib.all (key: (builtins.match "[a-z_]+" key) != null) (builtins.attrNames gamerules)
                ) "minecraft:";
                gamerule = "${minecraftPrefix}${rawGamerule}";
              in
              "gamerule ${gamerule} ${toValidString gamerules.${rawGamerule}}";

            jsonFiles =
              mapAttrs
                (
                  name: json:
                  writeText name (
                    builtins.readFile (
                      runCommand "formatted-${name}"
                        {
                          json = builtins.toJSON json;
                          buildInputs = [ jq ];
                        }
                        ''
                          jq -r '.' <(echo "$json") > $out
                        ''
                    )
                  )
                )
                {
                  loadJson.values = [ "declarative_gamerules:setup" ];
                  packMcmeta.pack = {
                    description = "Set minecraft gamerules using nix";
                    min_format = [
                      88
                      0
                    ];
                    max_format = [
                      88
                      0
                    ];
                  };
                };
          in

          stdenvNoCC.mkDerivation {
            pname = "declarative-gamerules";
            version = "1.0.0";

            src = writeText "setup.mcfunction" (concatStringsSep "\n" (map toGamerule (attrNames gamerules)));

            dontUnpack = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/data/{minecraft/tags/function,declarative_gamerules/function}
              ln -s ${config.packages.nix-minecraft-logomark}/icon.png $out/pack.png
              ln -s ${jsonFiles.packMcmeta} $out/pack.mcmeta
              ln -s ${jsonFiles.loadJson} $out/data/minecraft/tags/function/load.json
              ln -s $src $out/data/declarative_gamerules/function/setup.mcfunction

              runHook postInstall
            '';

            meta = {
              description = "Set minecraft gamerules using nix";
              license = lib.licenses.gpl3;
              maintainers = [ lib.maintainers.nanoyaki ];
            };
          }
        ) { };
      };
    };

  flake.overlays.logos =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) nix-minecraft-logomark thelessone-minecraft-logomark;
      }
    );

  flake.overlays.declarative-gamerules =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) declarative-gamerules;
      }
    );
}
