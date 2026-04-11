{
  flake.nixosModules.sentinel-caddy =
    { pkgs, config, ... }:

    {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/mholt/caddy-l4@v0.0.0-20260116154418-93f52b6a03ba"
            "github.com/caddyserver/transform-encoder@v0.0.0-20251203163749-3574c321422b"
          ];
          hash = "sha256-tbkIKgkeWJw+oHO3BAY9iBv2Z8zabz0XgIj+/UBdz18=";
        };

        logFormat = ''
          level DEBUG
          format transform "{ts} {request>remote_ip} → {request>method} {request>uri} {status} {size} \"{request>headers>User-Agent>[0]}\" ({duration})"
        '';

        extraConfig = ''
          (error_handling) {
            handle_errors {
              root * ${pkgs.thelessDotOne}
              try_files {path} /{err.status_code}.html /index.html
              file_server {
                status 200
              }
            }
          }
        '';

        globalConfig = ''
          layer4 {
            :2222 {
              @ssh ssh
              route @ssh {
                proxy at01.theless.one:22
              }
            }
          }
        '';

        virtualHosts."theless.one" = {
          useACMEHost = "theless.one";
          inherit (config.services.caddy) logFormat;
          extraConfig = ''
            @vpn remote_ip 100.64.64.0/24
            handle @vpn {
              reverse_proxy 100.64.64.1
            }

            handle {
              reverse_proxy at01.theless.one
            }

            import error_handling
          '';
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
