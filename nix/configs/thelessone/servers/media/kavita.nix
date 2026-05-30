{
  flake.nixosModules.thelessone-kavita =
    { lib, config, ... }:

    let
      cfg = config.services.kavita;
      plh = config.sops.placeholder;
    in

    {
      sops.secrets = {
        "kavita/key" = { };
        "kavita/oidc-id" = { };
        "kavita/oidc-secret" = { };
      };

      sops.templates."kavita.json" = {
        content = builtins.toJSON (
          lib.recursiveUpdate cfg.settings {
            TokenKey = plh."kavita/key";
            OpenIdConnectSettings = {
              ClientId = plh."kavita/oidc-id";
              Secret = plh."kavita/oidc-secret";
            };
          }
        );
        owner = "kavita";
        mode = "400";
      };

      systemd.services.kavita = {
        wantedBy = lib.mkForce [ "server-services.target" ];

        serviceConfig.LoadCredential = lib.mkForce "";
        serviceConfig.ReadOnlyPaths = [ config.sops.templates."kavita.json".path ];
        preStart = lib.mkForce ''
          ln -sf ${config.sops.templates."kavita.json".path} ${cfg.dataDir}/config/appsettings.json
        '';
      };

      services.kavita = {
        enable = true;
        tokenKeyFile = "/run/secrets/dummy";
        settings.Port = 3300;
        settings.OpenIdConnectSettings = {
          Enabled = true;
          Authority = "https://id.theless.one";
          CustomScopes = [ ];
        };
      };

      thelessone.caddy.vHost."books.theless.one" = {
        proxy.port = config.services.kavita.settings.Port;
        useTailnet = true;
      };

      thelessone.backups.kavita.paths = [ config.services.kavita.dataDir ];
    };
}
