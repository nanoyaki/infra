{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) genAttrs;

  # String -> String
  mkFileServer = directory: ''
    root * ${directory}
    file_server * browse
  '';

  # String -> String
  mkRedirect = url: ''
    redir ${url} permanent
  '';
in

{
  sops.secrets = {
    "caddy-env-vars/nik" = { };
    "caddy-env-vars/hana" = { };
    "caddy-env-vars/shared" = { };
    "caddy-env-vars/thelessone" = { };
  };

  sops.templates."caddy-users.env".file = (pkgs.formats.keyValue { }).generate "caddy-users.env" {
    nik = "nik ${config.sops.placeholder."caddy-env-vars/nik"}";
    hana = "hana ${config.sops.placeholder."caddy-env-vars/hana"}";
    shared = "user ${config.sops.placeholder."caddy-env-vars/shared"}";
    thelessone = "thelessone ${config.sops.placeholder."caddy-env-vars/thelessone"}";
  };

  services.caddy = {
    enable = true;
    package = lib.mkForce (
      pkgs.caddy.withPlugins {
        plugins = [
          "github.com/caddyserver/cache-handler@v0.16.0"
          "github.com/gr33nbl00d/caddy-revocation-validator@v1.0.5"
        ];
        hash = "sha256-dzmdZIP426n/nr1110ah4Z2+r4q/nlyk/a1PXMElXNs=";
      }
    );
    environmentFile = config.sops.templates."caddy-users.env".path;

    virtualHosts = {
      "na55l3zepb4kcg0zryqbdnay.theless.one".extraConfig = mkFileServer "/var/www/theless.one";
      "legacyfiles.theless.one".extraConfig = mkFileServer "/var/lib/caddy/files";

      "vappie.space".extraConfig = mkRedirect "https://bsky.app/profile/vappie.space";
      "www.vappie.space".extraConfig = mkRedirect "https://bsky.app/profile/vappie.space";
      "twitter.vappie.space".extraConfig = mkRedirect "https://x.com/vappie_";
    };
  };

  sops.templates."porkbun.json".content = builtins.toJSON {
    secretapikey = config.sops.placeholder."porkbun/secret-api-key";
    apikey = config.sops.placeholder."porkbun/api-key";
  };

  config'.caddy = {
    enable = true;
    openFirewall = true;
    baseDomain = "theless.one";
    porkbunCreds = config.sops.templates."porkbun.json".path;

    vHost."restic.theless.one" = {
      proxy.host = "10.0.0.6";
      proxy.port = 8000;
      useVpn = true;
    };
  };

  users.users.${config.services.caddy.user}.extraGroups = [ "mtls" ];

  systemd.tmpfiles.settings."10-caddy-directories" =
    genAttrs
      [
        "/var/www/theless.one"
        "/var/lib/caddy/files"
        "/var/lib/caddy/nanoyaki-files"
      ]
      (_: {
        d = {
          inherit (config.services.caddy) group user;
          mode = "2770";
        };
      });

  sops.secrets."restic/caddy" = { };

  config'.restic.backups.caddy = {
    repository = "/mnt/raid/backups/caddy";
    passwordFile = config.sops.secrets."restic/caddy".path;

    basePath = "/var";
    paths = [
      "www/theless.one"
      "lib/caddy/files"
      "lib/caddy/nanoyaki-files"
    ];

    timerConfig.OnCalendar = "daily";
  };
}
