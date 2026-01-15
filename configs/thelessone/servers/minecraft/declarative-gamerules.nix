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

  installPhase = ''
    runHook preInstall

    mkdir -p $out/data/{minecraft/tags/function,declarative_gamerules/function}
    ln -s ${./icon.png} $out/pack.png
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
