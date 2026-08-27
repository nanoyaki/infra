{ withSystem, self, ... }:

let
  query = ''
    [
      (if type == "array" then .[] else . end)
      | .files[0] as $f
      | .loaders[] as $l
      | .game_versions[] as $gv
      | {
          loader: $l,
          game_version: ($gv | gsub("\\."; "_")),
          version: (.version_number | gsub("[\\-\\+\\.]"; "_")),
          date_published: .date_published,
          file: { name: ($f.filename | gsub(" "; "-")), url: $f.url, sha512: $f.hashes.sha512 }
        }
    ]
    | sort_by(.loader, (.game_version | test("^\\d+\\_\\d+")), (.game_version | [scan("\\d+") | tonumber]), .date_published)
    | reverse
    | reduce .[] as $i ({};
        .[$i.loader][$i.game_version].latest //= $i.file
        | if $version == "latest" then . else .[$i.loader][$i.game_version][$i.version] = $i.file end
      )
    | . * $existing
  '';
in

{
  flake.nixosModules.thelessone-minecraft-modpacks =
    { lib, pkgs, ... }:

    let
      inherit (lib) types mkOption;
    in

    {
      options.services.minecraft-servers.modpacks = mkOption {
        type = types.attrsOf (
          types.submodule (
            { name, config, ... }:

            let
              mkVersion =
                version:

                lib.replaceStrings [ "." "+" "-" ] (lib.replicate 3 "_") (
                  if (builtins.match "^[^a-zA-Z].*" version) != null then "v${version}" else version
                );

              mkName = lib.replaceString "." "_";
            in

            {
              options = {
                mcVersion = mkOption {
                  type = types.str;
                  description = ''
                    The version that the modpack and all it's mods run on
                  '';
                };

                loader = mkOption {
                  type = types.enum [
                    "fabric"
                    "neoforge"
                  ];
                  description = ''
                    The mod loader to use
                  '';
                };

                mods = mkOption {
                  type = types.attrsOf (
                    types.either types.str (
                      types.submodule (mod: {
                        options.id = mkOption {
                          type = types.str;
                          default = mod.name;
                        };

                        options.version = mkOption {
                          type = types.str;
                        };
                      })
                    )
                  );
                  default = { };
                };

                datapacks = mkOption {
                  type = types.attrsOf (
                    types.either types.str (
                      types.submodule (mod: {
                        options.id = mkOption {
                          type = types.str;
                          default = mod.name;
                        };

                        options.version = mkOption {
                          type = types.str;
                        };
                      })
                    )
                  );
                  default = { };
                };

                packages = mkOption {
                  type = types.listOf types.package;
                  default = map (
                    mod:

                    pkgs.minecraft.${config.loader}.${mkVersion config.mcVersion}.${
                      mkName (config.mods.${mod}.id or mod)
                    }.${mkVersion (config.mods.${mod}.version or config.mods.${mod})}
                  ) (builtins.attrNames config.mods);
                };

                package = mkOption {
                  type = types.package;
                  default = pkgs.linkFarmFromDrvs "modpack-${name}-mc${config.mcVersion}-${config.loader}" config.packages;
                };
              };
            }
          )
        );
        default = { };
      };
    };

  perSystem =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib)
        foldr
        importJSON
        recursiveUpdate
        recurseIntoAttrs
        mapAttrs'
        readDir
        attrNames
        replaceString
        removeSuffix
        ;

      mkVersion =
        version: if (builtins.match "^[^a-zA-Z].*" version) != null then "v${version}" else version;
    in

    {
      packages.update-mods =
        let
          jobs =
            lib.concatMapStringsSep "\n"
              (job: ''
                ${lib.getExe config.packages.update-mod} "${job.id}" \
                  '${job.loader}' \
                  '${job.mcVersion}' \
                  '${job.version}'
              '')
              (
                lib.foldl
                  (
                    final: pack:
                    final
                    ++ (lib.mapAttrsToList (name: mod: {
                      id = mod.id or name;
                      loader = builtins.toJSON [ pack.loader ];
                      mcVersion = builtins.toJSON [ pack.mcVersion ];
                      version = mod.version or mod;
                    }) pack.mods)
                    ++ (lib.mapAttrsToList (name: datapack: {
                      id = datapack.id or name;
                      loader = builtins.toJSON [ "datapack" ];
                      mcVersion = builtins.toJSON [ pack.mcVersion ];
                      version = datapack.version or datapack;
                    }) pack.datapacks)
                  )
                  [ ]
                  (builtins.attrValues self.nixosConfigurations.thelessone.config.services.minecraft-servers.modpacks)
              );
        in

        pkgs.writeShellScriptBin "update-mods.sh" ''
          [[ ! -f "flake.nix" ]] && { echo "Please run this script in the project's root!"; exit 1; }
          pushd nix/configs/thelessone/servers/games/minecraft/modpacks

          rm _sources/*
          ${jobs}

          popd
        '';

      packages.update-mod = pkgs.writeShellApplication {
        name = "update-mod";
        runtimeInputs = with pkgs; [
          curl
          jq
        ];
        text = ''
          AGENT="''${AGENT:-"nanoyaki/infra/main (contact@nanoyaki.space)"}"
          RATELIMIT_STATE="''${XDG_STATE_HOME:-$HOME/.local/state}/modrinth-ratelimit"
          [[ ! -d "$(dirname "$RATELIMIT_STATE")" ]] && mkdir -p "$(dirname "$RATELIMIT_STATE")"
          [[ ! -f "$RATELIMIT_STATE" ]] && date +%s > "$RATELIMIT_STATE"

          project="$1"
          loader="''${2:-}"
          mcVersion="''${3:-}"
          version="''${4:-}"
          verbose="''${verbose:-}"
          debug="''${debug:-"$verbose"}"

          [[ -z "$project" ]] && { echo "Project missing!"; exit 1; }

          log() {
            local message="$1"
            echo "[INFO] $message" 1>&2
          }

          debug() {
            local message="$1"
            if [[ -n "$debug" ]]; then echo -e "\e[0;33m[DEBUG] $message\e[0m" 1>&2; fi
          }

          verbose() {
            local message="$1"
            if [[ -n "$verbose" ]]; then echo -e "\e[0;33m[VERBOSE] $message\e[0m" 1>&2; fi
          }

          parse_header() {
            file="$1"
            header="$2"

            cat "$file" | grep -oP '(?<='"$header"': )[^ ]*'
          }

          send_request() {
            local curlArgs headers nextRequest now remaining resetsIn until response

            curlArgs=()
            [[ -n "$loader" ]] && curlArgs+=("--data-urlencode" "loaders=$loader")
            [[ -n "$mcVersion" ]] && curlArgs+=("--data-urlencode" "game_versions=$mcVersion")
            [[ -n "$verbose" ]] && curlArgs+=("-v")

            nextRequest="$(cat "$RATELIMIT_STATE" 2> /dev/null || date +%s)"
            now="$(date +%s)"
            (( nextRequest > now )) && sleep $(( nextRequest - now ))

            headers=$(mktemp)

            debug "Using the following curl arguments: ''${curlArgs[*]}"
            response="$(
              curl -A "$AGENT" \
                -G "https://api.modrinth.com/v2/project/$project/version" "''${curlArgs[@]}" \
                -D "$headers" -s
            )"

            remaining="$(parse_header "$headers" "x-ratelimit-remaining")"
            resetsIn="$(parse_header "$headers" "x-ratelimit-reset")"
            if [[ "''${remaining:-0}" == "0" && -n "$resetsIn" ]]; then
              until=$(( $(date +%s) + resetsIn ))
              log "Rate limited until: $(date -d "@$until" +"%H:%M:%S")"
              echo "$until" > "$RATELIMIT_STATE"
            fi

            rm "$headers"
            echo "$response"
          }

          existing="{}"
          [[ -f "_sources/$project.json" ]] && existing="$(cat "_sources/$project.json")"

          log "Requesting project $project at version $version..."
          response="$(
            send_request \
            | jq -r '
                sort_by(.date_published)
                | if $version != "latest"
                  then .[] | select(.version_number == $version)
                  else .[0]
                  end
              ' \
              --arg version "$version"
          )"

          verbose "Parsed response: $response"
          existing="$(
            echo "$response" \
            | jq -r '${query}' \
              --argjson existing "$existing" \
              --arg version "$version"
          )"

          [[ -n "$existing" ]] && echo "$existing" > "_sources/$project.json"
          verbose "Result: $existing"
        '';

        meta.mainProgram = "update-mod";
      };

      # This code is absolutely terrible haha
      legacyPackages.minecraft = foldr (
        filename: attrs:

        let
          sources = importJSON (./_sources + "/${filename}");
          project = replaceString "." "_" (removeSuffix ".json" filename);
        in

        recursiveUpdate attrs (
          recurseIntoAttrs (
            mapAttrs' (loader: gameVersions: {
              name = loader;
              value = recurseIntoAttrs (
                mapAttrs' (gameVersion: projectVersions: {
                  name = mkVersion gameVersion;
                  value = recurseIntoAttrs (
                    foldr (
                      projectVersion: attrs:
                      recursiveUpdate attrs {
                        ${project}.${mkVersion projectVersion} = pkgs.fetchurl projectVersions.${projectVersion};
                      }
                    ) { } (attrNames projectVersions)
                  );
                }) gameVersions
              );
            }) sources
          )
        )
      ) { } (attrNames (readDir ./_sources));
    };

  flake.overlays.minecraft =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.legacyPackages) minecraft;
      }
    );
}
