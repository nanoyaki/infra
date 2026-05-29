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
          version: (.version_number | gsub("(^v?|[\\-\\+]?" + $gv + "[\\-\\+]?|[\\-\\+]?(" + "fabric|quilt|" + $l + ")[\\-\\+]?)+"; "") | gsub("\\."; "_")),
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
  flake.overlays.minecraft =
    final: prev:

    let
      inherit (prev.lib)
        foldr
        importJSON
        elemAt
        splitString
        recursiveUpdate
        recurseIntoAttrs
        mapAttrs'
        readDir
        attrNames
        ;
    in

    {
      # This code is absolutely terrible haha
      minecraft = foldr (
        filename: attrs:
        let
          sources = importJSON (./_sources + "/${filename}");
          project = elemAt (splitString "." filename) 0;
        in
        recursiveUpdate attrs (
          recurseIntoAttrs (
            mapAttrs' (loader: gameVersions: {
              name = loader;
              value = recurseIntoAttrs (
                mapAttrs' (
                  gameVersion: projectVersions:
                  let
                    mkVer = ver: if (builtins.match "^[0-9].*" ver) != null then "v${ver}" else ver;
                  in
                  {
                    name = mkVer gameVersion;
                    value = recurseIntoAttrs (
                      foldr (
                        projectVersion: attrs:
                        recursiveUpdate attrs {
                          ${project}."${mkVer projectVersion}" = final.fetchurl projectVersions.${projectVersion};
                        }
                      ) { } (attrNames projectVersions)
                    );
                  }
                ) gameVersions
              );
            }) sources
          )
        )
      ) { } (attrNames (readDir ./_sources));
    };

  perSystem =
    { lib, pkgs, ... }:

    {
      packages.update-fods =
        pkgs.writeShellScriptBin "update-fods"
          (lib.evalModules { modules = [ ./_module.nix ]; }).config.projects;

      packages.update-fod = pkgs.writeShellApplication {
        name = "update-fod";
        runtimeInputs = with pkgs; [ curl ];
        text = ''
          AGENT="''${AGENT:-"nanoyaki/infra/latest (contact@nanoyaki.space)"}"
          RATELIMIT_STATE="''${XDG_STATE_HOME:-$HOME/.local/state}/modrinth-ratelimit"
          [[ ! -d "$(dirname "$RATELIMIT_STATE")" ]] && mkdir -p "$(dirname "$RATELIMIT_STATE")"
          [[ ! -f "$RATELIMIT_STATE" ]] && date +%s > "$RATELIMIT_STATE"

          project="$1"
          loader="''${2:-}"
          mcVersion="''${3:-}"
          version="''${4:-}"

          [[ -z "$project" ]] && { echo "Project missing!"; exit 1; }

          parse_header() {
            file="$1"
            header="$2"

            cat "$file" | grep -oP '(?<='"$header"': )[^ ]*'
          }

          send_request() {
            local curlArgs headers nextRequest now remaining resetsIn slugVersion until

            curlArgs=()
            [[ -n "$loader" ]] && curlArgs+=("--data-urlencode" "loaders=$loader")
            [[ -n "$mcVersion" ]] && curlArgs+=("--data-urlencode" "game_versions=$mcVersion")

            nextRequest="$(cat "$RATELIMIT_STATE" 2> /dev/null || date +%s)"
            now="$(date +%s)"
            (( nextRequest > now )) && sleep $(( nextRequest - now ))

            headers=$(mktemp)

            slugVersion=""
            [[ -n "$version" && "$version" != "latest" ]] && slugVersion="/$version"

            echo "Requesting project $project..."
            curl -A "$AGENT" \
              -G "https://api.modrinth.com/v2/project/$project/version$slugVersion" "''${curlArgs[@]}" \
              -D "$headers" -o "$project-data.tmp" -s

            remaining="$(parse_header "$headers" "x-ratelimit-remaining")"
            resetsIn="$(parse_header "$headers" "x-ratelimit-reset")"
            if [[ "''${remaining:-0}" == "0" && -n "$resetsIn" ]]; then
              until=$(( $(date +%s) + resetsIn ))
              echo "Rate limited until: $(date -d "@$until" +"%H:%M:%S")"
              echo "$until" > "$RATELIMIT_STATE"
            fi

            rm "$headers"
          }

          send_request

          existing="{}"
          [[ -f "_sources/$project.json" ]] && existing="$(cat "_sources/$project.json")"

          result=$(
            jq '${query}' \
              --argjson existing "$existing" \
              --arg version "$version" \
              "$project-data.tmp"
          )
          [[ -n "$result" ]] && echo "$result" > "_sources/$project.json"

          rm "$project-data.tmp"
        '';
      };
    };
}
