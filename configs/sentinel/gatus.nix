{ config, ... }:

{
  services.gatus = {
    enable = true;

    settings = {
      web.port = 10000;

      maintenance = {
        enabled = true;
        start = "04:00";
        duration = "30m";
        timezone = "Europe/Berlin";
        every = [ ];
      };

      endpoints =
        map

          (
            endpoint:
            {
              enabled = true;
              interval = "5m";
              method = "GET";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 1000"
              ];
            }
            // endpoint
          )

          [
            {
              name = "Homepage";
              url = "https://theless.one";
            }
            {
              name = "Dashboard";
              url = "https://home.theless.one";
            }
          ];
    };
  };

  services.caddy.virtualHosts."status.theless.one" = {
    useACMEHost = "theless.one";
    extraConfig = ''
      reverse_proxy localhost:${toString config.services.gatus.settings.web.port}

      import error_handling
    '';
  };
}
