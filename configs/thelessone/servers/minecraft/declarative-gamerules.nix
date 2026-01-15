{
  lib,
  runCommand,
  writeText,
  jq,
  gamerules ? { },
}:

let
  inherit (lib)
    concatStringsSep
    map
    attrNames
    isBool
    mapAttrs
    ;

  toValidString =
    actual: if isBool actual then (if actual then "true" else "false") else toString actual;
  toGamerule =
    rawGamerule:

    let
      # Support 1.21.11
      gamerule = "${lib.optionalString (!(lib.hasInfix ":" rawGamerule)) "minecraft:"}${rawGamerule}";
    in

    "gamerule ${gamerule} ${toValidString gamerules.${rawGamerule}}";
  renderedGamerules = writeText "setup.mcfunction" (
    concatStringsSep "\n" (map toGamerule (attrNames gamerules))
  );

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
          description = "Sets gamerules declaratively";
          pack_format = 81;
          supported_formats = [
            81
            81
          ];
        };
      };
in

runCommand "declarative-gamerules"
  {
    icon = ./icon.png;
    inherit (jsonFiles) loadJson packMcmeta;
    inherit renderedGamerules;
  }
  ''
    mkdir -p $out/data/{minecraft/tags/function,declarative_gamerules/function}
    ln -s $packMcmeta $out/pack.mcmeta
    ln -s $loadJson $out/data/minecraft/tags/function/load.json
    ln -s $renderedGamerules $out/data/declarative_gamerules/function/setup.mcfunction
    ln -s $icon $out/pack.png
  ''
