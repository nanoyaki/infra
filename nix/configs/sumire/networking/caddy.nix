{
  flake.nixosModules.sumire-caddy =
    { lib, config, ... }:

    let
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
        openFirewall = true;
        email = "contact@nanoyaki.space";

        globalConfig = ''
          auto_https disable_certs
          storage file_system {
            root /var/cache/caddy
          }
        '';

        logFormat = mkForce ''
          output file /var/log/caddy/caddy.log {
            roll_size 100mb
            roll_keep 10
          }
          output stderr
          format console
          level INFO
        '';
      };
    };
}
