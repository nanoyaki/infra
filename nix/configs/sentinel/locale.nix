{
  flake.nixosModules.sentinel-locale =
    let
      english = "en_GB.UTF-8";
    in

    {
      console.keyMap = "de";
      time.timeZone = "Europe/Berlin";

      i18n.defaultLocale = "en_GB.UTF-8";
      i18n.extraLocales = [ "${english}/UTF-8" ];
      i18n.extraLocaleSettings = {
        LC_MESSAGES = "en_GB.UTF-8";
        LC_ADDRESS = english;
        LC_IDENTIFICATION = english;
        LC_MEASUREMENT = english;
        LC_MONETARY = english;
        LC_NAME = english;
        LC_NUMERIC = english;
        LC_PAPER = english;
        LC_TELEPHONE = english;
        LC_TIME = english;
        LC_COLLATE = english;
        LC_CTYPE = english;
      };
    };
}
