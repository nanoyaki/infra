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
        plugins = [ "github.com/caddyserver/cache-handler@v0.16.0" ];
        hash = "sha256-Oq79YKHMd2sZVapTYqoe/xlZuyTL0JBpUIRnKL+bOFI=";
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

  services.borgbackup.jobs.caddy = {
    repo = "thelessone-borg@10.0.0.6:caddy";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var";
    patterns = [
      "+ /var/www/theless.one"
      "+ /var/lib/caddy/files"
      "+ /var/lib/caddy/nanoyaki-files"
      "- **"
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
}
