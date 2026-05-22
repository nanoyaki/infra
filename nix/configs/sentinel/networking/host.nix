{
  flake.nixosModules.sentinel-host = {
    networking = {
      hostId = "3077d2d8";
      hostName = "sentinel";
      domain = "theless.one";
      fqdn = "de01.theless.one";
    };

    services.iperf3 = {
      enable = true;
      openFirewall = true;
    };

    sentinel.caddy.host."*.theless.one".config = ''
      reverse_proxy at01.theless.one {
          header_up Host {host}
          header_up X-Real-IP {remote}
          header_up X-Forwarded-For {remote}
          header_up X-Forwarded-Proto {scheme}
      }
    '';
  };
}
