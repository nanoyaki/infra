{
  nix.settings = {
    substituters = [ "https://cache.flox.dev" ];
    trusted-public-keys = [ "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=" ];
  };

  nixpkgs.config.cudaSupport = true;

  nixpkgs.overlays = [
    (_: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          pyFinal: pyPrev:
          let
            optionalOverlay = override: prev: pyFinal.${override} or (pyPrev.${prev} or { });
          in
          {
            torch = optionalOverlay "torch-bin" "torch";
            torchvision = optionalOverlay "torchvision-bin" "torchvision";
          }
        )
      ];
    })
  ];
}
