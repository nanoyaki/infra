{
  lib,
  config,
  pkgs,
  ...
}:

# TODO: create a proper module to reuse and order code

let
  wallpaper = pkgs.fetchPixivIllust {
    pixivId = 139667080;
    hash = "sha256-DtiyzMmxC7qpHc77eUcxRtpJOGSWGYMxabl1+WuFCY8=";
  };
in

{
  nixpkgs.overlays = [
    (final: _: {
      dashboardIcons = final.fetchFromGitHub {
        owner = "homarr-labs";
        repo = "dashboard-icons";
        rev = "4788bf85545871e1b47b272b5746982c33a999ea";
        hash = "sha256-46rJVRuuVfUzGBySALdpYdU3m1dxE74XuXmCWbL1Aig=";
      };
    })
  ];

  sops.secrets = {
    "dashboard/jellyfin" = { };
    "dashboard/audiobookshelf" = { };
    "dashboard/immich" = { };
    "dashboard/jellyseerr" = { };
    "dashboard/flood-username" = { };
    "dashboard/flood-password" = { };
    "dashboard/sabnzbd" = { };
    "dashboard/tandoor" = { };
    "dashboard/radarr" = { };
    "dashboard/sonarr" = { };
    "dashboard/lidarr" = { };
    "dashboard/bazarr" = { };
    "dashboard/prowlarr" = { };

    "dashboard/latitude" = { };
    "dashboard/longitude" = { };
  };

  sops.templates."homepage-secrets.env".file =
    (pkgs.formats.keyValue { }).generate "homepage-secrets.env.template"
      {
        HOMEPAGE_VAR_JELLYFIN_API_KEY = config.sops.placeholder."dashboard/jellyfin";
        HOMEPAGE_VAR_AUDIOBOOKSHELF_API_KEY = config.sops.placeholder."dashboard/audiobookshelf";
        HOMEPAGE_VAR_IMMICH_API_KEY = config.sops.placeholder."dashboard/immich";
        HOMEPAGE_VAR_JELLYSEERR_API_KEY = config.sops.placeholder."dashboard/jellyseerr";
        HOMEPAGE_VAR_FLOOD_USERNAME = config.sops.placeholder."dashboard/flood-username";
        HOMEPAGE_VAR_FLOOD_PASSWORD = config.sops.placeholder."dashboard/flood-password";
        HOMEPAGE_VAR_SABNZBD_API_KEY = config.sops.placeholder."dashboard/sabnzbd";
        HOMEPAGE_VAR_TANDOOR_API_KEY = config.sops.placeholder."dashboard/tandoor";
        HOMEPAGE_VAR_RADARR_API_KEY = config.sops.placeholder."dashboard/radarr";
        HOMEPAGE_VAR_SONARR_API_KEY = config.sops.placeholder."dashboard/sonarr";
        HOMEPAGE_VAR_LIDARR_API_KEY = config.sops.placeholder."dashboard/lidarr";
        HOMEPAGE_VAR_BAZARR_API_KEY = config.sops.placeholder."dashboard/bazarr";
        HOMEPAGE_VAR_PROWLARR_API_KEY = config.sops.placeholder."dashboard/prowlarr";

        HOMEPAGE_VAR_LATITUDE = config.sops.placeholder."dashboard/latitude";
        HOMEPAGE_VAR_LONGITUDE = config.sops.placeholder."dashboard/longitude";
      };

  config'.caddy.vHost."home.theless.one" = {
    proxy.port = config.services.homepage-dashboard.listenPort;
    useVpn = true;
  };

  services.homepage-dashboard = {
    enable = true;
    listenPort = 33189;
    allowedHosts = lib.concatStringsSep "," [
      "home.theless.one"
      "localhost:33189"
      "127.0.0.1:33189"
      "100.64.64.1:33189"
    ];
    environmentFile = config.sops.templates."homepage-secrets.env".path;

    package = pkgs.homepage-dashboard.overrideAttrs (prevAttrs: {
      nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [
        pkgs.imagemagick
      ];

      postInstall = ''
        mkdir -p $out/share/homepage/public/images
        # Reduce image size to about 100kb
        magick ${wallpaper} \
          -resize 1920x1080\! \
          -quality 95 \
          $out/share/homepage/public/images/${wallpaper.name}.webp
      '';
    });

    settings = {
      # Meta
      title = "theless.one";
      description = "A list of all services running on theless.one";
      startUrl = "https://home.theless.one";
      language = "en";
      disableIndexing = true;
      # We use nix after all
      hideVersion = true;
      disableUpdateCheck = true;

      # Theming
      headerStyle = "clean";
      background = {
        image = "/images/${wallpaper.name}.webp";
        blur = "xs";
        brightness = 50;
        saturate = 50;
        opacity = 50;
      };
      favicon = "https://theless.one/favicon.ico";
      theme = "dark";
      color = "slate";
      cardBlur = "xs";

      layout = [
        {
          General = {
            header = false;
            style = "row";
            columns = 3;
          };
        }
        {
          Media.style = "column";
        }
        {
          Downloads.style = "column";
        }
        {
          "User services" = {
            style = "column";
          };
        }
        {
          "Arr admin".style = "row";
        }
        {
          Manga = {
            style = "row";
            columns = 4;
          };
        }
      ];

      # Launching applications
      target = "_blank";
      quicklaunch = {
        searchDescriptions = true;
        hideInternetSearch = true;
        showSearchSuggestions = true;
        hideVisitURL = true;
        provider = "duckduckgo";

        mobileButtonPosition = "bottom-right";
      };
    };

    widgets = [
      { logo.icon = "https://theless.one/assets/nix.svg"; }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
          showSearchSuggestions = true;
          focus = true;
        };
      }
      {
        openmeteo = {
          label = "Austria - Server";
          latitude = "{{HOMEPAGE_VAR_LATITUDE}}";
          longitude = "{{HOMEPAGE_VAR_LONGITUDE}}";
          timezone = "Austria/Vienna";
          units = "metric";
          cache = 5;
          format.maximumFractionDigits = 1;
        };
      }
    ];

    bookmarks = [
      {
        General = [
          {
            Discord = [
              {
                icon = "discord.svg";
                href = "https://discord.com/channels/1392204217141301338";
                description = "The Discord server";
              }
            ];
          }
          {
            "Minecraft chat" = [
              {
                icon = "minecraft.svg";
                href = "https://discord.com/channels/1392204217141301338/1395405287984201738";
                description = "Discord chat linked with the Minecraft chat";
              }
            ];
          }
          {
            Issues = [
              {
                icon = "forgejo.svg";
                href = "https://git.theless.one/nanoyaki/theless.one-issues/issues";
                description = "Report issues here";
              }
            ];
          }
        ];
      }
    ];

    services = [
      {
        Media = [
          {
            Jellyfin = rec {
              icon = "jellyfin.svg";
              href = "https://jellyfin.theless.one";
              siteMonitor = href;
              description = "Media library";
              widget = {
                type = "jellyfin";
                url = href;
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                enableNowPlaying = false;
                enableMediaControl = false;
                fields = [
                  "movies"
                  "series"
                  "episodes"
                ];
              };
            };
          }
          {
            Audiobookshelf = rec {
              icon = "audiobookshelf.svg";
              href = "https://audiobookshelf.theless.one";
              siteMonitor = href;
              description = "Photo backups";
              widget = {
                type = "audiobookshelf";
                url = href;
                key = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_API_KEY}}";
                fields = [
                  "books"
                  "booksDuration"
                ];
              };
            };
          }
          {
            Immich = rec {
              icon = "immich.svg";
              href = "https://immich.theless.one/";
              siteMonitor = href;
              description = "Photo backups";
              widget = {
                type = "immich";
                url = href;
                key = "{{HOMEPAGE_VAR_IMMICH_API_KEY}}";
                version = 2;
                fields = [
                  "photos"
                  "videos"
                  "storage"
                ];
              };
            };
          }
          {
            Fireshare = {
              icon = "fireshare.webp";
              href = "https://fireshare.theless.one/#/login";
              siteMonitor = "https://fireshare.theless.one";
              description = "Clip sharing";
            };
          }
        ];
      }
      {
        "User services" = [
          {
            Actual = rec {
              icon = "actual-budget.svg";
              href = "https://finances.theless.one";
              siteMonitor = href;
              description = "Finance management";
            };
          }
          {
            Tandoor = rec {
              icon = "tandoor-recipes.svg";
              href = "https://recipes.theless.one";
              siteMonitor = href;
              description = "Recipe management";
              widget = {
                type = "tandoor";
                url = href;
                key = "{{HOMEPAGE_VAR_TANDOOR_API_KEY}}";
                fields = [ "recipes" ];
              };
            };
          }
          {
            Copyparty = rec {
              icon = "copyparty.svg";
              href = "https://files.theless.one";
              siteMonitor = href;
              description = "File server";
            };
          }
          {
            Vaultwarden = rec {
              icon = "vaultwarden.svg";
              href = "https://vaultwarden.theless.one";
              siteMonitor = href;
              description = "Password manager";
            };
          }
          {
            Forgejo = rec {
              icon = "forgejo.svg";
              href = "https://git.theless.one";
              siteMonitor = href;
              description = "Code forge";
            };
          }
        ];
      }
      {
        Downloads = [
          {
            Jellyseerr = rec {
              icon = "jellyseerr.svg";
              href = "https://jellyseerr.theless.one";
              siteMonitor = href;
              description = "Media requests";
              widget = {
                type = "jellyseerr";
                url = href;
                key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
                fields = [
                  "pending"
                  "available"
                  "issues"
                ];
              };
            };
          }
          {
            Flood = rec {
              icon = "flood.svg";
              href = "https://flood.theless.one";
              siteMonitor = href;
              description = "Webinterface for deluge";
              widget = {
                type = "flood";
                url = href;
                username = "{{HOMEPAGE_VAR_FLOOD_USERNAME}}";
                password = "{{HOMEPAGE_VAR_FLOOD_PASSWORD}}";
                fields = [
                  "leech"
                  "seed"
                  "download"
                  "upload"
                ];
              };
            };
          }
          {
            Sabnzbd = rec {
              icon = "sabnzbd.svg";
              href = "https://sabnzbd.theless.one";
              siteMonitor = href;
              description = "Newznab client";
              widget = {
                type = "sabnzbd";
                url = href;
                key = "{{HOMEPAGE_VAR_SABNZBD_API_KEY}}";
                fields = [
                  "rate"
                  "queue"
                  "timeleft"
                ];
              };
            };
          }
        ];
      }
      {
        Manga = [
          {
            Mei = rec {
              icon = "suwayomi.svg";
              href = "https://mei-manga.theless.one";
              siteMonitor = href;
              description = "Mei's mangas";
              widget = {
                type = "suwayomi";
                url = href;
              };
            };
          }
          {
            Hana = rec {
              icon = "suwayomi.svg";
              href = "https://hana-manga.theless.one";
              siteMonitor = href;
              description = "Hana's mangas";
              widget = {
                type = "suwayomi";
                url = href;
              };
            };
          }
          {
            Thomas = rec {
              icon = "suwayomi.svg";
              href = "https://manga.theless.one";
              siteMonitor = href;
              description = "Thomas' mangas";
              widget = {
                type = "suwayomi";
                url = href;
              };
            };
          }
          {
            Nik = rec {
              icon = "suwayomi.svg";
              href = "https://nik-manga.theless.one";
              siteMonitor = href;
              description = "Nik's mangas";
              widget = {
                type = "suwayomi";
                url = href;
              };
            };
          }
        ];
      }
      {
        "Arr admin" = [
          {
            Radarr = rec {
              icon = "radarr.svg";
              href = "https://radarr.theless.one";
              siteMonitor = href;
              description = "Movie management";
              widget = {
                type = "radarr";
                url = href;
                key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
                enableQueue = true;
                fields = [
                  "wanted"
                  "missing"
                  "queued"
                ];
              };
            };
          }
          {
            Sonarr = rec {
              icon = "sonarr.svg";
              href = "https://sonarr.theless.one";
              siteMonitor = href;
              description = "Show management";
              widget = {
                type = "sonarr";
                url = href;
                key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
                enableQueue = true;
                fields = [
                  "wanted"
                  "queued"
                ];
              };
            };
          }
          {
            Lidarr = rec {
              icon = "lidarr.svg";
              href = "https://lidarr.theless.one";
              siteMonitor = href;
              description = "Music management";
              widget = {
                type = "lidarr";
                url = href;
                key = "{{HOMEPAGE_VAR_LIDARR_API_KEY}}";
                fields = [
                  "wanted"
                  "queued"
                  "artists"
                ];
              };
            };
          }
          {
            Shoko = rec {
              icon = "shoko.svg";
              href = "https://shoko.theless.one";
              siteMonitor = href;
              description = "Anime management";
            };
          }
          {
            Bazarr = rec {
              icon = "bazarr.svg";
              href = "https://bazarr.theless.one";
              siteMonitor = href;
              description = "Subtitle management";
              widget = {
                type = "bazarr";
                url = href;
                key = "{{HOMEPAGE_VAR_BAZARR_API_KEY}}";
                fields = [
                  "missingEpisodes"
                  "missingMovies"
                ];
              };
            };
          }
          {
            Prowlarr = rec {
              icon = "prowlarr.svg";
              href = "https://prowlarr.theless.one";
              siteMonitor = href;
              description = "Indexer management";
              widget = {
                type = "prowlarr";
                url = href;
                key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
                fields = [
                  "numberOfGrabs"
                  "numberOfQueries"
                ];
              };
            };
          }
        ];
      }
    ];
  };
}
