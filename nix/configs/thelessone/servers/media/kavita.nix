{
  flake.nixosModules.thelessone-kavita =
    { lib, config, ... }:

    let
      cfg = config.services.kavita;

      inherit (config)
        prt
        dmn
        plh
        tpl
        ;
    in

    {
      prt.kavita = 8017;
      dmn.kavita = "books.theless.one";

      sec = {
        "kavita/key" = { };
        "kavita/oidc-id" = { };
        "kavita/oidc-secret" = { };
      };

      tpl."kavita.json" = {
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
        serviceConfig.ReadOnlyPaths = [ tpl."kavita.json".path ];
        preStart = lib.mkForce ''
          ln -sf ${tpl."kavita.json".path} ${cfg.dataDir}/config/appsettings.json
        '';
      };

      services.kavita = {
        enable = true;
        tokenKeyFile = "/run/secrets/dummy";
        settings.Port = prt.kavita;
        settings.OpenIdConnectSettings = {
          Enabled = true;
          Authority = "https://${dmn.pocket-id}";
          CustomScopes = [ ];
        };
      };

      thelessone.caddy.vHost.${dmn.kavita} = {
        proxy.port = prt.kavita;
        useTailnet = true;
      };

      thelessone.backups.kavita.paths = [ config.services.kavita.dataDir ];
    };
}
