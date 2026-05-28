{ withSystem, ... }:

{
  _module.args.preferNewerOverlay =
    package: _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        ${package} =
          if
            prev.lib.versionOlder config.packages.${package}.version (prev.${package}.version or "0.0.0")
          then
            prev.${package}
          else
            config.packages.${package};
      }
    );
}
