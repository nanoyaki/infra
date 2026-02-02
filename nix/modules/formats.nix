{ withSystem, ... }:

{
  perSystem =
    { lib, pkgs, ... }:

    let
      inherit (lib) mapAttrs hasInfix replaceStrings;

      toEnv =
        attrs:

        mapAttrs (
          _: value: if hasInfix "'" value then replaceStrings [ "'" ] [ "\\'" ] value else value
        ) attrs;
    in

    {
      legacyPackages = {
        writeEnv = name: (pkgs.formats.keyValue { }).generate name toEnv;
        writeEnv' = opts: name: (pkgs.formats.keyValue opts).generate name toEnv;
        writeYaml = name: attrs: (pkgs.formats.yaml { }).generate name attrs;
      };
    };

  flake.overlays.formats =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.legacyPackages) writeEnv writeEnv';
      }
    );
}
