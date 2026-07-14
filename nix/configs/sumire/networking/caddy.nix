{
  flake.nixosModules.sumire-caddy =
    { lib, config, ... }:

    let
      inherit (config) prt;
      inherit (lib) mkForce;

      cfg = config.services.caddy;
    in

    {
      systemd.tmpfiles.settings."10-caddy"."/var/cache/caddy".d = {
        inherit (cfg) user group;
        mode = "750";
      };

      services.caddy = {
        enable = true;
        email = "contact@nanoyaki.space";

        globalConfig = ''
          storage file_system {
            root /var/cache/caddy
          }
        '';

        logFormat = mkForce ''
          output file /var/log/caddy/caddy.log {
            roll_size 100mb
            roll_keep 10
          }
          format console
          level INFO
        '';

        virtualHosts."serdexmethylpheni.date".extraConfig = ''
          @livekitwss {
            path /_livekit/sfu /_livekit/sfu/*
          }

          handle @livekitwss {
            reverse_proxy [::1]:${toString config.services.livekit.settings.port}
          }

          @livekitjwt {
            path /_livekit/jwt /_livekit/jwt/*
          }

          handle @livekitjwt {
            reverse_proxy [::1]:${toString config.services.lk-jwt-service.port}
          }

          reverse_proxy [::1]:${toString prt.continuwuity}
        '';
      };
    };
}
