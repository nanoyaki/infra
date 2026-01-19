{ pkgs, ... }:

{
  services.caddy = {
    enable = true;

    logFormat = ''
      level INFO
      format console
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

    virtualHosts."theless.one" = {
      serverAliases = [ "*.theless.one" ];
      useACMEHost = "theless.one";
      extraConfig = ''
        @vpn remote_ip 100.64.64.0/24

        reverse_proxy @vpn 100.64.64.1 localhost {
          lb_policy first

          fail_duration 30s
          max_fails 2
          unhealthy_status 4xx 5xx
        }

        reverse_proxy at01.theless.one {
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
