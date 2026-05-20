{ withSystem, ... }:

{
  _module.args.preferNewerOverlay =
    package: _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        ${package} =
          if prev.lib.versionOlder config.packages.${package}.version prev.${package}.version then
            prev.${package}
          else
            config.packages.${package};
      }
    );
}
