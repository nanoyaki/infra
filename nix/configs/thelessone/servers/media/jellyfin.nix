{ withSystem, ... }:

{
  flake.nixosModules.thelessone-jellyfin =
    { pkgs, config, ... }:

    let
      backupPath = "/var/lib/jellyfin";
    in

    {
      services.jellyfin = {
        enable = true;
        package = pkgs.jellyfin.override { inherit (pkgs) jellyfin-web; };
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."jellyfin.theless.one" = {
        proxy.port = 8096;
        pangolin.name = "Jellyfin";
      };

      users.users.${config.services.jellyfin.user}.extraGroups = [
        "video"
        "render"
      ];

      systemd.services.borgbackup-job-jellyfin.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.jellyfin = {
        repo = "/mnt/raid/borgbackup/jellyfin";
        doInit = true;

        paths = backupPath;
        patterns = [
          "- ${backupPath}/metadata/library"
          "- ${backupPath}/data/subtitles"
        ];

        encryption.mode = "none";
        compression = "zstd";

        startAt = "daily";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 14;
          weekly = 12;
          monthly = -1;
        };
      };
    };

  perSystem =
    { pkgs, ... }:

    {
      packages.jellyfin-web = pkgs.jellyfin-web.overrideAttrs (prevAttrs: {
        postPatch = prevAttrs.postPatch or "" + ''
          sed -i 's/elem\.target = [^;]*/elem.target = "_self"' \
            src/controllers/session/login/index.js
        '';

        postInstall =
          let
            episodePreview =
              ''<script plugin="InPlayerEpisodePreview" version="1.5.0.0"''
              + ''src="/InPlayerPreview/ClientScript" async></script>'';
          in
          prevAttrs.postInstall or ""
          + ''
            install -m600 $out/share/jellyfin-web/main.jellyfin.bundle.js \
              main.jellyfin.bundle.js
            sed -i 's/enableBackdrops:function(){return [^}]*}/enableBackdrops:function(){return E}/' \
              main.jellyfin.bundle.js
            install -m444 main.jellyfin.bundle.js \
              $out/share/jellyfin-web/main.jellyfin.bundle.js

            install -m600 $out/share/jellyfin-web/index.html \
              index.html
            sed -i 's#</body>#${episodePreview}</body>#' \
              index.html
            install -m444 index.html \
              $out/share/jellyfin-web/index.html
          '';
      });
    };

  flake.overlays.jellyfin-web =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) jellyfin-web;
      }
    );
}
