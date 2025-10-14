{ lib, ... }:

let
  inherit (lib) listToAttrs map;
in

{
  config'.caddy.vHost = {
    "https://vpn.theless.one".extraConfig = ''
      redir https://theless.one 301
    '';
  }
  // listToAttrs (
    map
      (service: {
        name = "https://${service}.vpn.theless.one";
        value.extraConfig = ''
          redir https://${service}.theless.one 301
        '';
      })
      [
        "jellyseerr"
        "stash"
        "flood"
        "immich"
        "sabnzbd"
        "gokapi"
        "prowlarr"
        "radarr"
        "shoko"
        "sonarr"
        "whisparr"
        "lidarr"
        "bazarr"
        "hana-manga"
        "nik-manga"
        "mei-manga"
        "manga"
      ]
  );
}
