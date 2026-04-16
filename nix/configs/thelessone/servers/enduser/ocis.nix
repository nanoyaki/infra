{
  flake.nixosModules.thelessone-ocis =
    { pkgs, config, ... }:

    let
      self = "'''self'''";
      none = "'''none'''";
      unsafeInline = "'''unsafe-inline'''";
      cspYaml = (pkgs.formats.yaml { }).generate "csp.yaml" {
        directives = {
          child-src = [ self ];
          connect-src = [
            self
            "blob:"
            "https://raw.githubusercontent.com/owncloud/awesome-ocis"
            "https://id.theless.one/"
          ];
          default-src = [ none ];
          font-src = [ self ];
          frame-ancestors = [ none ];
          frame-src = [
            self
            "blob:"
            "https://embed.diagrams.net/"
          ];
          img-src = [
            self
            "data:"
            "blob:"
            "https://raw.githubusercontent.com/owncloud/awesome-ocis/"
          ];
          manifest-src = [ self ];
          media-src = [ self ];
          object-src = [
            self
            "blob:"
          ];
          script-src = [
            self
            unsafeInline
          ];
          style-src = [
            self
            unsafeInline
          ];
        };
      };

      cfg = config.services.ocis;
    in

    {
      sops.secrets.ocis-jwt = { };
      sops.secrets.ocis-client-id = { };
      sops.templates."ocis.env".file = pkgs.writeEnv "ocis.env.template" {
        OCIS_JWT_SECRET = config.sops.placeholder.ocis-jwt;
        WEB_OIDC_CLIENT_ID = config.sops.placeholder.ocis-client-id;
      };

      services.ocis = {
        enable = true;
        package = pkgs.ocis;
        url = "https://cloud.theless.one";

        environmentFile = config.sops.templates."ocis.env".path;
        environment = {
          PROXY_TLS = "false";
          OCIS_INSECURE = "true";

          OCIS_MAX_CONCURRENT_REQUESTS = "0";
          OCIS_REQUEST_TIMEOUT = "0";

          DEMO_USERS = "false";
          IDM_CREATE_DEMO_USERS = "false";

          OCIS_OIDC_ISSUER = "https://id.theless.one";
          PROXY_OIDC_REWRITE_WELLKNOWN = "true";
          PROXY_AUTOPROVISION_ACCOUNTS = "true";
          PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
          PROXY_USER_OIDC_CLAIM = "preferred_username";
          PROXY_CSP_CONFIG_FILE_LOCATION = cspYaml.outPath;
        };
      };

      services.newt.blueprint.public-resources.owncloud-infinite-scale = {
        name = "ownCloud Infinite Scale";
        protocol = "http";
        full-domain = "cloud.theless.one";
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            inherit (config.services.ocis) port;
            method = "http";
          }
        ];
      };

      systemd.services.borgbackup-job-ocis.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.ocis = {
        repo = "/mnt/raid/borgbackup/ocis";
        doInit = true;

        paths = cfg.stateDir;

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
}
