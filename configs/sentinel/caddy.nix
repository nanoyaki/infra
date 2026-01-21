{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/mholt/caddy-l4@v0.0.0-20260116154418-93f52b6a03ba"
        "github.com/caddyserver/transform-encoder@v0.0.0-20251203163749-3574c321422b"
      ];
      hash = "sha256-6vy3S9hidO98sh2VosGTSK32sTus0aeNrqs+mpGgX4A=";
    };

    logFormat = ''
      level INFO
      format transform "{ts} {request>remote_ip} → {request>method} {request>uri} {status} {size} \"{request>headers>User-Agent>[0]}\" ({duration})"
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
        :22 {
          @ssh-tls {
              tls
              sni git.theless.one
          }
          route @ssh-tls {
              tls
              proxy at01.theless.one:22
          }

          @raw-ssh ssh
          route @raw-ssh {
              proxy de01.theless.one:22
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
