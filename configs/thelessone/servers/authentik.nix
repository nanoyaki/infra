{
  inputs,
  pkgs,
  config,
  ...
}:

let
  env = pkgs.formats.keyValue { };
in

{
  imports = [ inputs.authentik-nix.nixosModules.default ];

  sops.secrets = {
    "authentik/secret" = { };
    "authentik/smtp-password" = { };
    "authentik/redis-password" = { };
    "authentik/bootstrap-password" = { };
  };

  sops.templates."authentik.env".file = env.generate "authentik.env.template" {
    AUTHENTIK_SECRET_KEY = config.sops.placeholder."authentik/secret";
    AUTHENTIK_EMAIL__PASSWORD = config.sops.placeholder."authentik/smtp-password";
  };

  services.authentik = {
    enable = true;
    environmentFile = config.sops.templates."authentik.env".path;
    settings = {
      email = {
        host = "theless.one";
        port = 587;
        username = "authentik@theless.one";
        use_tls = true;
        use_ssl = false;
        from = "authentik@theless.one";
      };
      listen.listen_http = "0.0.0.0:9000";
      disable_startup_analytics = true;
      avatars = "gravatar";
    };
  };

  config'.caddy.vHost."https://auth.theless.one".proxy.port = 9000;
}
