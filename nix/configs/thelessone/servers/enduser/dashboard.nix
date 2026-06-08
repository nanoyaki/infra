{ withSystem, ... }:

{
  flake.nixosModules.thelessone-dashboard =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    # TODO: create a proper module to reuse and order code

    {
      sops.secrets = {
        "dashboard/jellyfin" = { };
        "dashboard/audiobookshelf" = { };
        "dashboard/immich" = { };
        "dashboard/jellyseerr" = { };
        "dashboard/flood-username" = { };
        "dashboard/flood-password" = { };
        "dashboard/sabnzbd" = { };
        "dashboard/radarr" = { };
        "dashboard/sonarr" = { };
        "dashboard/lidarr" = { };
        "dashboard/bazarr" = { };
        "dashboard/prowlarr" = { };
        "dashboard/speedtest" = { };

        "dashboard/latitude" = { };
        "dashboard/longitude" = { };
      };

      sops.templates."homepage-secrets.env".file = pkgs.writeEnv "homepage-secrets.env.template" {
        HOMEPAGE_VAR_JELLYFIN_API_KEY = config.sops.placeholder."dashboard/jellyfin";
        HOMEPAGE_VAR_AUDIOBOOKSHELF_API_KEY = config.sops.placeholder."dashboard/audiobookshelf";
        HOMEPAGE_VAR_IMMICH_API_KEY = config.sops.placeholder."dashboard/immich";
        HOMEPAGE_VAR_JELLYSEERR_API_KEY = config.sops.placeholder."dashboard/jellyseerr";
        HOMEPAGE_VAR_FLOOD_USERNAME = config.sops.placeholder."dashboard/flood-username";
        HOMEPAGE_VAR_FLOOD_PASSWORD = config.sops.placeholder."dashboard/flood-password";
        HOMEPAGE_VAR_SABNZBD_API_KEY = config.sops.placeholder."dashboard/sabnzbd";
        HOMEPAGE_VAR_RADARR_API_KEY = config.sops.placeholder."dashboard/radarr";
        HOMEPAGE_VAR_SONARR_API_KEY = config.sops.placeholder."dashboard/sonarr";
        HOMEPAGE_VAR_LIDARR_API_KEY = config.sops.placeholder."dashboard/lidarr";
        HOMEPAGE_VAR_BAZARR_API_KEY = config.sops.placeholder."dashboard/bazarr";
        HOMEPAGE_VAR_PROWLARR_API_KEY = config.sops.placeholder."dashboard/prowlarr";
        HOMEPAGE_VAR_SPEEDTEST_API_KEY = config.sops.placeholder."dashboard/speedtest";

        HOMEPAGE_VAR_LATITUDE = config.sops.placeholder."dashboard/latitude";
        HOMEPAGE_VAR_LONGITUDE = config.sops.placeholder."dashboard/longitude";
      };

      thelessone.caddy.vHost."home.theless.one" = {
        proxy.port = config.services.homepage-dashboard.listenPort;
        useTailnet = true;
      };

      systemd.services.homepage-dashboard.wantedBy = lib.mkForce [ "server-services.target" ];
      services.homepage-dashboard = {
        enable = true;
        openFirewall = true;
        listenPort = 33189;
        allowedHosts = lib.concatStringsSep "," [
          "home.theless.one"
          "localhost:33189"
          "127.0.0.1:33189"
          "100.64.0.1:33189"
          "[fd64::1]:33189"
        ];
        environmentFiles = [ config.sops.templates."homepage-secrets.env".path ];

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
            image = "/images/${pkgs.dashboard-wallpaper.name}.webp";
            blur = "xs";
            brightness = 50;
            saturate = 50;
            opacity = 50;
          };
          favicon = "https://theless.one/assets/favicon.ico";
          theme = "dark";
          color = "slate";
          cardBlur = "xs";

          statusStyle = "dot";
          useEqualHeights = true;
          layout = [
            {
              General = {
                header = false;
                style = "row";
                columns = 3;
              };
            }
            {
              Resources = {
                header = false;
                style = "row";
                columns = 4;
              };
            }
            {
              Media = {
                header = false;
                style = "row";
                columns = 4;
              };
            }
            {
              Public = {
                header = false;
                style = "row";
                columns = 4;
              };
            }
            {
              Private = {
                header = false;
                style = "row";
                columns = 4;
              };
            }
            {
              Manga = {
                header = false;
                style = "row";
                columns = 3;
              };
            }
            {
              Downloads = {
                style = "row";
                columns = 2;
                initiallyCollapsed = true;
              };
            }
            {
              Administration = {
                style = "row";
                columns = 4;
                initiallyCollapsed = true;
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
          { logo.icon = "https://theless.one/assets/logo.svg"; }
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
            Resources =
              let
                glances = metric: {
                  widget = {
                    type = "glances";
                    url = "http://127.0.0.1:${toString config.services.glances.port}";
                    inherit metric;
                    version = 4;
                    pointsLimit = 20;
                  };
                };
              in
              [
                {
                  "CPU Usage" = glances "cpu";
                }
                {
                  "Memory Usage" = glances "memory";
                }
                {
                  "Network Attached Storage".widget = {
                    type = "glances";
                    url = "http://10.0.0.6:${toString config.services.glances.port}";
                    metric = "fs:/moon";
                    version = 4;
                    pointsLimit = 20;
                  };
                }
                {
                  "Internal Storage" = glances "fs:/";
                }
                {
                  "Network Usage" = glances "network:enp9s0";
                }
                {
                  "VPN Network Usage" = glances "network:${config.services.tailscale.interfaceName}";
                }
                {
                  Speedtest.widget = {
                    type = "speedtest";
                    url = "http://localhost:28920";
                    version = 2;
                    key = "{{HOMEPAGE_VAR_SPEEDTEST_API_KEY}}";
                    bitratePrecision = 3;
                    fields = [
                      "download"
                      "upload"
                      "ping"
                    ];
                  };
                }
                {
                  Processes = glances "process";
                }
              ];
          }
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
                    version = 2;
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
            ];
          }
          {
            Public = [
              {
                "Pocket ID" = rec {
                  icon = "pocket-id.svg";
                  href = "https://id.theless.one";
                  siteMonitor = href;
                  description = "Identity management";
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
                Speedtest = rec {
                  icon = "sh-speedtest-tracker-dark.svg";
                  href = "https://speedtest.theless.one";
                  siteMonitor = href;
                  description = "Network speed monitor";
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
            Private = [
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
                };
              }
              {
                Cloud = rec {
                  icon = "owncloud.svg";
                  href = "https://cloud.theless.one";
                  siteMonitor = href;
                  description = "Cloud storage";
                };
              }
              {
                Papra = rec {
                  icon = "papra.svg";
                  href = "https://papra.theless.one";
                  siteMonitor = href;
                  description = "Document archive";
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
            ];
          }
          {
            Administration = [
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
                Shoko = rec {
                  icon = "shoko.svg";
                  href = "https://shoko.theless.one";
                  siteMonitor = href;
                  description = "Anime management";
                };
              }
              {
                Glances = rec {
                  icon = "glances.svg";
                  href = "https://glances.theless.one";
                  siteMonitor = href;
                  description = "Resource monitor";
                };
              }
            ];
          }
          {
            Downloads = [
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
        ];
      };
    };

  perSystem =
    { pkgs, config, ... }:

    {
      legacyPackages.fetchPixivIllust = pkgs.callPackage (
        {
          lib,
          stdenvNoCC,
          curl,
          jq,
          cacert,
        }:

        {
          pixivId,
          pages ? [ 0 ],
          allPages ? false,
          hash ? "",
        }:

        let
          parsedId = if lib.isInt pixivId then toString pixivId else pixivId;

          pagesScript =
            if allPages then
              builtins.warn (
                "It's not recommended to use allPages."
                + " Using it may lead to irreproducible behaviour if the author"
                + " of the illustration decides to modify the page count."
              ) "pages=$(seq 0 $((pageCount - 1)))"
            else
              "pages=(${lib.concatMapStringsSep " " (page: "\"${toString page}\"") pages})";
        in

        stdenvNoCC.mkDerivation {
          name = "illust-${parsedId}-pages-${lib.concatMapStringsSep "-" toString pages}";

          nativeBuildInputs = [
            curl
            jq
          ];

          env.SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

          dontUnpack = true;
          dontConfigure = true;
          dontFixup = true;

          buildPhase = ''
            runHook preBuild

            id="${parsedId}"

            # Retrieve metadata
            metadata="$(
              curl --fail -S \
                -H "Accept: application/json" \
                -H "Referer: https://www.pixiv.net/artworks/$id" \
                "https://www.pixiv.net/ajax/illust/$id"
            )"

            # Verify that page numbers don't exceed page count
            pageCount="$(echo "$metadata" | jq -r '.body.pageCount')"
            ${pagesScript}

            for page in $pages; do
              if (( $page >= $pageCount )); then
                >&2 echo "Page number $page exceeds the total page count of $pageCount page(s)."
                exit 1
              fi
            done

            artworkUrl="$(echo "$metadata" | jq -r '.body.urls.original')"

            for page in $pages; do
              local url="''${artworkUrl/_p0/_p$page}"
              curl --fail -S \
                -H "Referer: https://www.pixiv.net/" \
                "$url" -O
            done

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            [[ ''${#pages[@]} > 1 ]] && mkdir -p $out
            cp "${parsedId}"* $out

            runHook postInstall
          '';

          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = hash;
        }
      ) { };

      legacyPackages.dashboard-wallpaper = config.legacyPackages.fetchPixivIllust {
        pixivId = 139667080;
        hash = "sha256-DtiyzMmxC7qpHc77eUcxRtpJOGSWGYMxabl1+WuFCY8=";
      };
    };

  flake.overlays.homepage-dashboard =
    final: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      let
        inherit (config.legacyPackages) dashboard-wallpaper;
      in

      {
        inherit dashboard-wallpaper;

        homepage-dashboard = prev.homepage-dashboard.overrideAttrs {
          postInstall = ''
            mkdir -p $out/share/homepage/public/images
            # Reduce image size to about 100kb
            ${final.lib.getExe' final.imagemagick "magick"} ${dashboard-wallpaper} \
              -resize 1920x1080\! \
              -quality 95 \
              $out/share/homepage/public/images/${dashboard-wallpaper.name}.webp
          '';
        };
      }
    );
}
