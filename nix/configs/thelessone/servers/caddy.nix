{
  flake.nixosModules.thelessone-caddy =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    {
      sops.secrets = {
        "caddy-env-vars/nik" = { };
        "caddy-env-vars/hana" = { };
        "caddy-env-vars/shared" = { };
        "caddy-env-vars/thelessone" = { };
      };

      sops.templates."caddy-users.env".file = pkgs.writeEnv "caddy-users.env" {
        nik = "nik ${config.sops.placeholder."caddy-env-vars/nik"}";
        hana = "hana ${config.sops.placeholder."caddy-env-vars/hana"}";
        shared = "user ${config.sops.placeholder."caddy-env-vars/shared"}";
        thelessone = "thelessone ${config.sops.placeholder."caddy-env-vars/thelessone"}";
      };

      services.caddy = {
        enable = true;
        environmentFile = config.sops.templates."caddy-users.env".path;

        virtualHosts =
          let
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
            "theless.one".extraConfig = ''
              root * ${pkgs.thelessDotOne}
              file_server
            '';
            "na55l3zepb4kcg0zryqbdnay.theless.one".extraConfig = mkFileServer "/var/www/theless.one";
            "legacyfiles.theless.one".extraConfig = mkFileServer "/var/lib/caddy/files";

            "vappie.space".extraConfig = mkRedirect "https://bsky.app/profile/vappie.space";
            "www.vappie.space".extraConfig = mkRedirect "https://bsky.app/profile/vappie.space";
            "twitter.vappie.space".extraConfig = mkRedirect "https://x.com/vappie_";
          };

        extraConfig = lib.mkForce ''
          (error_handling) {
            handle_errors {
              root * ${pkgs.thelessDotOne}
              try_files {path} /{err.status_code}.html /index.html
              file_server {
                status 200
              }
            }
          }
        '';
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
    };

  flake.overlays.caddy = final: _: {
    thelessDotOne = final.fetchFromGitea {
      domain = "git.theless.one";
      owner = "nanoyaki";
      repo = "theless.one";
      rev = "c98e1b01f036e7bccc249cce444bc1e542efd5b3";
      hash = "sha256-IR9Ml+/WecD+6twUzM3Mzk+CGqrYrkOKt3JHZ/N6fZ4=";
    };
  };
}
