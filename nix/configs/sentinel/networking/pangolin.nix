{
  flake.nixosModules.sentinel-pangolin =
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
        "mail/no-reply" = { };
      };

      sops.templates."pangolin.env" = {
        file = pkgs.writeEnv "pangolin.env.template" {
          SERVER_SECRET = plh."pangolin/server-secret";
          PANGOLIN_SETUP_TOKEN = plh."pangolin/setup-token";
          EMAIL_SMTP_PASS = plh."mail/no-reply";
        };
        restartUnits = [ "pangolin.service" ];
      };

      networking.nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = "enp9s0";
        internalInterfaces = [ "wg0" ];
      };

      networking.firewall.allowedUDPPorts = [
        51820
        21820
      ];

      services.gerbil.environmentFile = "/etc/nixos/secrets/gerbil.env";
      services.traefik.environmentFiles = [ tpl."theless.one-acme.env".path ];
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
