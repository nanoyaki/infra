{
  flake.nixosModules.sentinel-mail =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (lib) mkOption;

      format = pkgs.formats.xml { };
      cfg = config.services.mailserver.autodiscovery;
    in

    {
      options.services.mailserver.autodiscovery.thunderbird.config = mkOption {
        inherit (format) type;
      };

      config = {
        services.mailserver.autodiscovery.thunderbird.config.clientConfig = {
          "@version" = "1.1";

          emailProvider = {
            "@id" = "thelessone";

            domain = [
              "nanoyaki.space"
              "theless.one"
              "aslija.com"
              "hanakretzer.de"
            ];

            displayName = "Nanoyaki.Space Mail";
            displayShortName = "Nanoyaki.Space";

            incomingServer = {
              "@type" = "imap";

              hostname = "mail.nanoyaki.space";
              port = 993;
              socketType = "SSL";
              username = "%EMAILADDRESS%";
              authentication = "password-cleartext";
            };

            outgoingServer = {
              "@type" = "smtp";

              hostname = "mail.nanoyaki.space";
              port = 465;
              socketType = "SSL";
              username = "%EMAILADDRESS%";
              authentication = "password-cleartext";
            };

            addressBook = {
              "@type" = "carddav";

              username = "%EMAILADDRESS%";
              authentication = "http-basic";
              serverURL = "https://dav.theless.one";
            };

            calendar = {
              "@type" = "caldav";

              username = "%EMAILADDRESS%";
              authentication = "http-basic";
              serverURL = "https://dav.theless.one";
            };
          };
        };

        services.caddy.virtualHosts."discover.nanoyaki.space".extraConfig = ''
          @thunderbird {
            method GET
            path /mail/config-v1.1.xml
          }

          handle @thunderbird {
            try_files ${(format.generate "config-v1.1.xml" cfg.thunderbird.config).outPath}
          }
        '';
      };
    };
}
