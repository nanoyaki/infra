{
  lib,
  runCommand,
  writeText,
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
  toGamerule = gamerule: "gamerule ${gamerule} ${toValidString gamerules.${gamerule}}";
  renderedGamerules = writeText "setup.mcfunction" (
    concatStringsSep "\n" (map toGamerule (attrNames gamerules))
  );

  jsonFiles = mapAttrs (name: json: writeText name (builtins.toJSON json)) {
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
    ln -s $packMcmeta > $out/pack.mcmeta
    ln -s $loadJson > $out/data/minecraft/tags/function/load.json
    ln -s $renderedGamerules $out/data/declarative_gamerules/function/setup.mcfunction
    ln -s $icon $out/pack.png
  ''
