{
  flake.nixosModules.thelessone-pangolin =
    {
      pkgs,
      config,
      ...
    }:

    let
      plh = config.sops.placeholder;
      tpl = config.sops.templates;
    in

    {
      sops.secrets = {
        "pangolin/server-secret" = { };
        "pangolin/setup-token" = { };
        "newt/secret" = { };
        "newt/id" = { };
      };

      sops.templates."pangolin.env" = {
        file = pkgs.writeEnv "pangolin.env.template" {
          SERVER_SECRET = plh."pangolin/server-secret";
          PANGOLIN_SETUP_TOKEN = plh."pangolin/setup-token";
          EMAIL_SMTP_PASS = plh.no-reply-password;
        };
        restartUnits = [
          "pangolin.service"
          "gerbil.service"
        ];
      };

      sops.templates."newt.env" = {
        file = pkgs.writeEnv "newt.env.template" {
          NEWT_SECRET = plh."newt/secret";
          NEWT_ID = plh."newt/id";
        };
        restartUnits = [ "newt.service" ];
      };

      networking.firewall.allowedUDPPorts = [
        51820
        21820
      ];
      services.gerbil.port = 51820;
      services.gerbil.environmentFile = "/etc/nixos/secrets/gerbil.env";

      services.traefik.dynamicConfigOptions = {
        http.routers.caddy-catchall = {
          rule = "HostRegexp(`^.+\\.theless\\.one$`) && !Host(`pangolin.theless.one`)";
          service = "caddy";
          priority = 1;
          tls.certResolver = "letsencrypt";
        };

        http.services.caddy.loadBalancer.servers.url = [ "http://localhost:2080" ];
      };

      services.traefik.environmentFiles = [ tpl."theless.one-acme.env".path ];

      networking.nat.internalInterfaces = [ "newt" ];
      services.newt = {
        enable = true;
        environmentFile = tpl."newt.env".path;
        settings.endpoint = "https://pangolin.theless.one";
      };

      services.pangolin = {
        enable = true;
        openFirewall = true;
        environmentFile = tpl."pangolin.env".path;

        baseDomain = "theless.one";
        dashboardDomain = "pangolin.theless.one";
        dnsProvider = "porkbun";
        letsEncryptEmail = "contact@nanoyaki.space";

        settings = {
          app.save_logs = true;

          domains.domain1 = {
            prefer_wildcard_cert = true;
          };

          traefik = {
            prefer_wildcard_cert = true;
            cert_resolver = "letsencrypt";
          };

          gerbil = {
            start_port = 51822;
            base_endpoint = "pangolin.theless.one";
            subnet_group = "100.50.0.0/20";
            site_block_size = 27;
          };

          email = {
            smtp_user = "no-reply@theless.one";
            no_reply = "no-reply@theless.one";

            smtp_host = "smtp.theless.one";
            smtp_port = 465;
            smtp_secure = true;
          };

          flags = {
            disable_signup_without_invite = true;
            disable_user_create_org = true;
          };
        };
      };
    };
}
