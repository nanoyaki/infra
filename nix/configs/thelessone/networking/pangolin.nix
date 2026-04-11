{
  flake.nixosModules.thelessone-pangolin =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    {
      sops.secrets = {
        "pangolin/server-secret" = { };
        "pangolin/setup-token" = { };
      };

      sops.templates."pangolin.env" = {
        file = pkgs.writeEnv "pangolin.env.template" {
          SERVER_SECRET = config.sops.placeholder."pangolin/server-secret";
          PANGOLIN_SETUP_TOKEN = config.sops.placeholder."pangolin/setup-token";
          EMAIL_SMTP_PASS = config.sops.placeholder.no-reply-password;
        };
        restartUnits = [
          "pangolin.service"
          "gerbil.service"
        ];
      };

      networking.firewall.allowedUDPPorts = [ 51822 ];
      services.gerbil.port = 51822;
      services.gerbil.environmentFile = "/etc/nixos/secrets/gerbil.env";

      # TODO: activate when switching from caddy to traefik
      # services.traefik.dynamicConfigOptions = {
      #   http.routers.caddy-catchall = {
      #     rule = "HostRegexp(`^.+\\.theless\\.one$`) && !Host(`pangolin.theless.one`)";
      #     service = "caddy";
      #     priority = 1;
      #     tls.certResolver = "letsencrypt";
      #   };

      #   http.services.caddy.loadBalancer.servers.url = [ "http://localhost:2080" ];
      # };

      services.traefik.environmentFiles = [ config.sops.templates."theless.one-acme.env".path ];
      services.traefik.staticConfigOptions.entryPoints = lib.mkForce {
        web.address = ":8080";
        websecure = {
          address = ":8443";
          transport.respondingTimeouts.readTimeout = "30m";
          http.tls.certResolver = "letsencrypt";
        };
      };

      thelessone.caddy.vHost."pangolin.theless.one".proxy.port = 8080;
      thelessone.caddy.vHost."*.theless.one".proxy.port = 8080;

      services.pangolin = {
        enable = true;
        # TODO: activate when switching from caddy to traefik
        # openFirewall = true;
        environmentFile = config.sops.templates."pangolin.env".path;

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
            subnet_group = "100.64.0.0/20";
            site_block_size = "27";
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
