{ withSystem, ... }:

{
  _module.args.preferNewerOverlay =
    package: _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        ${package} =
          let
            overlayVersion = config.packages.${package}.version;
            upstreamVersion = prev.${package}.version or "0.0.0";
          in

          if prev.lib.versionOlder overlayVersion upstreamVersion then
            builtins.warn (
              "Not using the defined overlay for package '${package}' since "
              + "it's version (${overlayVersion}) is older than the upstream "
              + "version (${upstreamVersion})"
            ) prev.${package}
          else
            config.packages.${package};
      }
    );
}
