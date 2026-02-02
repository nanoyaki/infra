{
  flake.nixosModules.thelessone-desktop =
    { pkgs, config, ... }:

    {
      environment.systemPackages = with pkgs; [
        tmux
        discord
        prismlauncher
      ];

      programs.firefox.package = pkgs.librewolf;
      environment.sessionVariables.BROWSER = config.programs.firefox.package.meta.mainProgram;

      xdg.mime.defaultApplications = {
        "text/html" = "librewolf.desktop";
        "application/pdf" = "librewolf.desktop";
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
      };
    };

  flake.homeModules.thelessone-desktop =
    { pkgs, ... }:

    let
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
    in

    {
      programs.librewolf = {
        enable = true;
        languagePacks = [
          "en-GB"
          "de"
        ];

        policies = {
          DontCheckDefaultBrowser = true;
          DisablePocket = true;
          DisableAppUpdate = true;
        };

        # https://github.com/hlissner/dotfiles/blob/28b2f8889c7a8d799c62dbab3729b1de18c6c1a5/modules/desktop/browsers/librewolf.nix
        settings = {
          # Allow svgs to take on theme colors
          "svg.context-properties.content.enabled" = true;
          "webgl.disabled" = false;
          # Neat feature, but i need dark mode
          "privacy.resistFingerprinting" = false;
          # Fuck AI
          "browser.ml.chat.enabled" = false;

          # Obey XDG
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "widget.use-xdg-desktop-portal.location" = 1;
          "widget.use-xdg-desktop-portal.mime-handler" = 1;
          "widget.use-xdg-desktop-portal.native-messaging" = 1;
          "widget.use-xdg-desktop-portal.open-uri" = 1;
          "widget.use-xdg-desktop-portal.settings" = 1;

          # Autoscroll
          "general.autoscroll" = true;
          "middlemouse.paste" = false;

          # Security
          "security.family_safety.mode" = 0;
          "security.pki.sha1_enforcement_level" = 1;
          "security.tls.enable_0rtt_data" = false;
          "geo.provider.network.url" =
            "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
          "geo.provider.use_gpsd" = false;

          # We set BROWSER already
          "browser.shell.checkDefaultBrowser" = false;
          # Disable these default extensions
          "extensions.pocket.enabled" = false;
          "extensions.unifiedExtensions.enabled" = false;
          "extensions.shield-recipe-client.enabled" = false;
          # Disable telemetry
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";
          "experiments.supported" = false;
          "experiments.enabled" = false;
          "experiments.manifest.uri" = "";
          "browser.ping-centre.telemetry" = false;
          # Disable crash reports
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          # Don't log out
          "privacy.clearOnShutdown.cookies" = false;
          "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
          "privacy.clearOnShutdown.sessions" = false;
        };

        profiles.default = {
          id = 0;
          name = "default";
          isDefault = true;
          search = {
            force = true;
            default = "ddg";
            privateDefault = "ddg";
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                inherit icon;
                definedAliases = [ "@np" ];
              };

              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                inherit icon;
                definedAliases = [ "@no" ];
              };

              "NixOS Wiki" = {
                urls = [
                  {
                    template = "https://wiki.nixos.org/w/index.php";
                    params = [
                      {
                        name = "search";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                inherit icon;
                definedAliases = [ "@nw" ];
              };
            };
          };
          extensions = {
            force = true;
            packages = with pkgs.nur.repos.rycee.firefox-addons; [
              ublock-origin
              keepa
              refined-github
              languagetool
              control-panel-for-twitter
              tampermonkey
              redirector
              reddit-enhancement-suite
              mullvad

              steam-database
              augmented-steam

              return-youtube-dislikes
              youtube-screenshot-button

              seventv
              betterttv
              twitch-auto-points
            ];
          };
        };
      };

      nixpkgs.allowUnfreeNames = [
        "keepa"
        "languagetool"
        "tampermonkey"
        "betterttv"
      ];

      xdg.mimeApps.defaultApplications = {
        "text/html" = "librewolf.desktop";
        "application/pdf" = "librewolf.desktop";
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
      };

      programs.mpv = {
        enable = true;

        config = {
          osc = "no";
          volume = 20;
        };

        scripts = with pkgs.mpvScripts; [
          sponsorblock
          thumbfast
          modernx
          mpv-discord
          mpv-subtitle-lines
          mpv-playlistmanager
          mpv-cheatsheet
        ];
      };

      xdg.mimeApps.defaultApplications = {
        "audio/*" = "mpv.desktop";
        "video/*" = "mpv.desktop";
      };

      xdg.autostart.enable = true;
    };
}
