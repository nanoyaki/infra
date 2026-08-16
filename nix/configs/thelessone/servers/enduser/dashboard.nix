{ inputs, withSystem, ... }:

{
  flake.nixosModules.thelessone-dashboard =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (config)
        prt
        dmn
        plh
        tpl
        ;

      thelessnas = inputs.self.nixosConfigurations.thelessnas.config;
    in
    # TODO: create a proper module to reuse and order code

    {
      sec = {
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

      tpl."homepage-secrets.env".file = pkgs.writeEnv "homepage-secrets.env.template" {
        HOMEPAGE_VAR_JELLYFIN_API_KEY = plh."dashboard/jellyfin";
        HOMEPAGE_VAR_AUDIOBOOKSHELF_API_KEY = plh."dashboard/audiobookshelf";
        HOMEPAGE_VAR_IMMICH_API_KEY = plh."dashboard/immich";
        HOMEPAGE_VAR_JELLYSEERR_API_KEY = plh."dashboard/jellyseerr";
        HOMEPAGE_VAR_FLOOD_USERNAME = plh."dashboard/flood-username";
        HOMEPAGE_VAR_FLOOD_PASSWORD = plh."dashboard/flood-password";
        HOMEPAGE_VAR_SABNZBD_API_KEY = plh."dashboard/sabnzbd";
        HOMEPAGE_VAR_RADARR_API_KEY = plh."dashboard/radarr";
        HOMEPAGE_VAR_SONARR_API_KEY = plh."dashboard/sonarr";
        HOMEPAGE_VAR_LIDARR_API_KEY = plh."dashboard/lidarr";
        HOMEPAGE_VAR_BAZARR_API_KEY = plh."dashboard/bazarr";
        HOMEPAGE_VAR_PROWLARR_API_KEY = plh."dashboard/prowlarr";
        HOMEPAGE_VAR_SPEEDTEST_API_KEY = plh."dashboard/speedtest";

        HOMEPAGE_VAR_LATITUDE = plh."dashboard/latitude";
        HOMEPAGE_VAR_LONGITUDE = plh."dashboard/longitude";
      };

      prt.homepage-dashboard = 8002;
      dmn.homepage-dashboard = "home.theless.one";

      thelessone.caddy.vHost.${dmn.homepage-dashboard} = {
        proxy.port = prt.homepage-dashboard;
        useTailnet = true;
      };

      systemd.services.homepage-dashboard.wantedBy = lib.mkForce [ "server-services.target" ];
      services.homepage-dashboard = {
        enable = true;
        listenPort = prt.homepage-dashboard;
        allowedHosts = dmn.homepage-dashboard;
        environmentFiles = [ tpl."homepage-secrets.env".path ];

        settings = {
          # Meta
          title = "Theless.one";
          description = "A list of all services running on theless.one";
          startUrl = "https://${dmn.homepage-dashboard}";
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
          { logo.icon = "https://${dmn.self}/assets/logo.svg"; }
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
                    href = "https://${dmn.git}/nanoyaki/theless.one-issues/issues";
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
                    url = "http://127.0.0.1:${toString prt.glances}";
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
                    url = "http://10.0.0.6:${toString thelessnas.prt.glances}";
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
                    url = "http://localhost:${toString prt.speedtest-internal}";
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
                  href = "https://${dmn.jellyfin}";
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
                  href = "https://${dmn.seerr}";
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
                  href = "https://${dmn.audiobookshelf}";
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
                  href = "https://${dmn.immich}";
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
                  href = "https://${dmn.pocket-id}";
                  siteMonitor = href;
                  description = "Identity management";
                };
              }
              {
                Vaultwarden = rec {
                  icon = "vaultwarden.svg";
                  href = "https://${dmn.vaultwarden}";
                  siteMonitor = href;
                  description = "Password manager";
                };
              }
              {
                Speedtest = rec {
                  icon = "sh-speedtest-tracker-dark.svg";
                  href = "https://${dmn.speedtest-tracker}";
                  siteMonitor = href;
                  description = "Network speed monitor";
                };
              }
              {
                Forgejo = rec {
                  icon = "forgejo.svg";
                  href = "https://${dmn.git}";
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
                  icon = "actual.svg";
                  href = "https://${dmn.finances}";
                  siteMonitor = href;
                  description = "Finance management";
                };
              }
              {
                Tandoor = rec {
                  icon = "tandoor-recipes.svg";
                  href = "https://${dmn.tandoor-recipes}";
                  siteMonitor = href;
                  description = "Recipe management";
                };
              }
              {
                Cloud = rec {
                  icon = "owncloud.svg";
                  href = "https://${dmn.opencloud}";
                  siteMonitor = href;
                  description = "Cloud storage";
                };
              }
              {
                Papra = rec {
                  icon = "papra.svg";
                  href = "https://${dmn.papra}";
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
                  href = "https://${dmn.suwayomi-mei}";
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
                  href = "https://${dmn.suwayomi-hana}";
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
                  href = "https://${dmn.suwayomi-thomas}";
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
                  href = "https://${dmn.sonarr}";
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
                  href = "https://${dmn.radarr}";
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
                  href = "https://${dmn.lidarr}";
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
                  href = "https://${dmn.prowlarr}";
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
                  href = "https://${dmn.bazarr}";
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
                Glances = rec {
                  icon = "glances.svg";
                  href = "https://${dmn.glances}";
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
                  href = "https://${dmn.flood}";
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
                  href = "https://${dmn.sabnzbd}";
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
