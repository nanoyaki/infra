{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/mholt/caddy-l4@93f52b6a03bac66a4321dd1c5287820e3c2a832c" ];
      hash = "sha256-s8D9p8k/Gote8s4fk0pv35R7aIwRi5ze7gbBHj+Fm8U=";
    };

    logFormat = ''
      level INFO
      format single_field '{ts} {remote} → {method} {uri} {status} {size} "{user_agent}" ({latency})'
    '';

    extraConfig = ''
      (error_handling) {
        handle_errors {
          root * ${
            pkgs.fetchFromGitea {
              domain = "git.theless.one";
              owner = "nanoyaki";
              repo = "theless.one";
              rev = "c98e1b01f036e7bccc249cce444bc1e542efd5b3";
              hash = "sha256-IR9Ml+/WecD+6twUzM3Mzk+CGqrYrkOKt3JHZ/N6fZ4=";
            }
          }
          try_files {path} /{err.status_code}.html /index.html
          file_server {
            status 200
          }
        }
      }
    '';

    globalConfig = ''
      layer4 {
        git.theless.one:22 {
          @ssh ssh
          route @ssh {
            proxy at01.theless.one:22 de01.theless.one:22
          }
        }
      }
    '';

    virtualHosts."theless.one" = {
      serverAliases = [ "*.theless.one" ];
      useACMEHost = "theless.one";
      extraConfig = ''
        @vpn remote_ip 100.64.64.0/24
        reverse_proxy @vpn 100.64.64.1 100.64.64.23 {
          lb_policy first

          fail_duration 30s
          max_fails 2
          unhealthy_status 4xx 5xx
        }

        @public not host at01.theless.one de01.theless.one
        reverse_proxy @public at01.theless.one de01.theless.one {
          lb_policy first

          fail_duration 30s
          max_fails 2
          unhealthy_status 4xx 5xx
        }

        import error_handling
      '';
    };
  };
}
