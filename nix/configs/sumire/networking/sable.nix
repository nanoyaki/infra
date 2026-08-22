{
  flake.nixosModules.sumire-sable =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib)
        types
        mkEnableOption
        mkOption
        literalExpression
        mkIf
        mkMerge
        ;

      settingsFormat = pkgs.formats.json { };
      cfg = config.services.sable;

    in

    {
      options.services.sable = {
        enable = mkEnableOption "sable, a web-client for matrix";

        settings = mkOption {
          type = types.submodule {
            freeformType = settingsFormat.type;

            options = {
              defaultHomeserver = mkOption {
                type = types.ints.between 0 (builtins.length cfg.settings.homeserverList);
                default = 0;
                example = literalExpression "1";
                description = ''
                  The index of the default homeserver in {option}`services.sable.settings.homeserverList`
                '';
              };

              homeserverList = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = literalExpression ''[ "sable.moe" "matrix.org" ]'';
                description = ''
                  A list of homeservers to advertise before logging in
                '';
              };

              allowCustomHomeservers = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to allow accessing homeservers not listed in {option}`services.sable.settings.homeserverList`
                '';
              };

              featuredCommunities = {
                openAsDefault = mkEnableOption "opening featured communities by default";

                spaces = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = ''
                    Featured spaces to advertise
                  '';
                };

                rooms = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = ''
                    Featured spaces to advertise
                  '';
                };

                servers = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
              };
            };
          };
          default = { };
        };
      };

      config = mkMerge [
        {
          services.sable.enable = true;
          services.sable.settings = {
            allowCustomHomeservers = false;
            defaultHomeserver = 0;
            homeserverList = [ config.services.matrix-continuwuity.settings.global.server_name ];

            featuredCommunities.rooms = [ "#general:serdexmethylpheni.date" ];
            featuredCommunities.servers = [
              "unredacted.org"
              "matrix.4d2.org"
            ];
          };
        }
        (mkIf cfg.enable {
          programs.dnscontrol.domains."serdexmethylpheni.date".cname.web.value = "@";

          services.caddy.virtualHosts."web.serdexmethylpheni.date" = {
            useACMEHost = "web.serdexmethylpheni.date";
            extraConfig = ''
              root * ${pkgs.sable.override { conf = cfg.settings; }}
              encode zstd gzip
              file_server {
                precompressed br
              }
              try_files {path} /index.html
            '';
          };

          security.acme.certs."web.serdexmethylpheni.date" = {
            environmentFile = config.tpl."porkbun.env".path;
            reloadServices = [ "caddy.service" ];
          };
        })
      ];
    };
}
