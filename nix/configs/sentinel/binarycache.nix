{
  flake.nixosModules.sentinel-binarycache =
    { pkgs, config, ... }:

    {
      sops = {
        secrets = {
          attic = { };
          s3-id = { };
          s3-key = { };
        };

        templates."attic.env".file = pkgs.writeEnv "attic.env.template" {
          ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 = config.sops.placeholder.attic;
          AWS_ACCESS_KEY_ID = config.sops.placeholder.s3-id;
          AWS_SECRET_ACCESS_KEY = config.sops.placeholder.s3-key;
        };
      };

      environment.systemPackages = [ pkgs.attic-client ];

      services.atticd = {
        enable = true;
        environmentFile = config.sops.templates."attic.env".path;

        mode = "monolithic";
        settings = {
          listen = "127.0.0.1:8005";
          allowed-hosts = [ "binarycache.theless.one" ];
          api-endpoint = "https://binarycache.theless.one/";

          storage = {
            type = "s3";
            bucket = "binary-cache";
            endpoint = "https://eu2.contabostorage.com";
          };

          garbage-collection = {
            interval = "12 hours";
            default-retention-period = "6 months";
          };
        };
      };

      services.caddy.virtualHosts."binarycache.theless.one".extraConfig = ''
        reverse_proxy 127.0.0.1:8005
      '';
    };
}
