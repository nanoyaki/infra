{
  flake.nixosModules.sumire-livekit =
    { pkgs, config, ... }:

    let
      inherit (config) plh tpl;
    in

    {
      sec."livekit/matrix-rtc-key" = { };
      sec."livekit/matrix-rtc-secret" = { };

      tpl."livekit.keys".file = pkgs.writeYaml "livekit.keys.template" {
        ${plh."livekit/matrix-rtc-key"} = plh."livekit/matrix-rtc-secret";
      };

      services.livekit = {
        enable = true;
        openFirewall = true;
        keyFile = tpl."livekit.keys".path;

        ingress.enable = true;

        settings = {
          port = 7880;
          room.auto_create = false;

          rtc = {
            tcp_port = 7881;
            use_external_ip = true;
            port_range_start = 50000;
            port_range_end = 50100;
          };
        };
      };

      systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS =
        "serdexmethylpheni.date";
      services.lk-jwt-service = {
        enable = true;
        port = 8080;
        livekitUrl = "wss://serdexmethylpheni.date/_livekit/sfu";
        keyFile = tpl."livekit.keys".path;
      };
    };
}
