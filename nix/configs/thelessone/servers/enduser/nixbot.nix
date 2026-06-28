{ inputs, ... }:

{
  flake.nixosModules.thelessone-nixbot =
    { config, ... }:

    {
      imports = [ inputs.nixbot.nixosModules.nixbot ];

      sops.secrets."nixbot/oidc-secret" = { };

      services.nixbot = {
        enable = true;
        # Generate HTTPs URLs
        useHTTPS = true;
        # Proxied through caddy
        nginx.enable = false;

        evalWorkerCount = 4;
        evalMaxMemorySize = 4096;

        gitea = {
          enable = true;
          instanceUrl = "https://git.theless.one";

        };

        oidc = {
          enable = true;
          name = "Pocket ID";
          discoveryUrl = "https://id.theless.one/.well-known/openid-configuration";
          clientId = "b7ace5ae-3fa8-4f47-aff2-827b7f493d60";
          clientSecretFile = config.sops.secrets."nixbot/oidc-secret".path;

          scope = [
            "openid"
            "email"
            "profile"
            "groups"
          ];

          mapping.username = "sub";
          mapping.groups = [ "groups" ];
        };

        database.createLocally = true;
      };
    };
}
