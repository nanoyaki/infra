{ pkgs, ... }:

{
  services.caddy = {
    enable = true;
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
      extraConfig = ''
        reverse_proxy 100.64.64.1 localhost {
          lb_policy first

          fail_duration 30
          max_fails 2
          unhealthy_status 4xx 5xx
        }

        import error_handling
      '';
    };
  };
}
