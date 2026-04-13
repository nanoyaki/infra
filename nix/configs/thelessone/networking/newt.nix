{
  flake.nixosModules.thelessone-newt =
    {
      pkgs,
      config,
      ...
    }:

    let
      plh = config.sops.placeholder;
      tpl = config.sops.templates;
    in

    {
      sops.secrets = {
        "newt/secret" = { };
        "newt/id" = { };
      };

      sops.templates."newt.env" = {
        file = pkgs.writeEnv "newt.env.template" {
          NEWT_SECRET = plh."newt/secret";
          NEWT_ID = plh."newt/id";
        };
        restartUnits = [ "newt.service" ];
      };

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = true;
        "net.ipv6.conf.all.forwarding" = true;
        "net.ipv6.conf.enp9s0.disable_ipv6" = true;
      };

      networking.nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = "enp9s0";
        internalInterfaces = [ "wg0" ];
      };

      networking.firewall.allowedUDPPorts = [
        51820
        21820
      ];

      services.newt = {
        enable = true;
        environmentFile = tpl."newt.env".path;
        settings.endpoint = "https://pangolin.theless.one";
      };
    };
}
