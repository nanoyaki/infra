{
  flake.homeModules.thelessone-xdg =
    { config, ... }:

    let
      inherit (config.home) homeDirectory;
    in

    {
      xdg.userDirs = {
        enable = true;
        setSessionVariables = true;

        desktop = "${homeDirectory}/Schreibtisch";
        download = "${homeDirectory}/Downloads";
        documents = "${homeDirectory}/Dokumente";

        videos = null;
        pictures = null;
        publicShare = null;
        templates = null;
        music = null;
      };
    };
}
