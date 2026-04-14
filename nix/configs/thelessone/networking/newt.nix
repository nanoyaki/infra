{
  flake.nixosModules.thelessone-newt =
    {
      lib,
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
        "olm/secret" = { };
        "olm/id" = { };
      };

      sops.templates."newt.env" = {
        file = pkgs.writeEnv "newt.env.template" {
          NEWT_SECRET = plh."newt/secret";
          NEWT_ID = plh."newt/id";
        };
        restartUnits = [ "newt.service" ];
      };

      sops.templates."olm.env" = {
        file = pkgs.writeEnv "olm.env.template" {
          OLM_SECRET = plh."olm/secret";
          OLM_ID = plh."olm/id";
        };
        restartUnits = [ "olm.service" ];
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

      environment.systemPackages = [ pkgs.pangolin-cli ];

      services.newt = {
        enable = true;
        environmentFile = tpl."newt.env".path;
        settings.endpoint = "https://pangolin.theless.one";
      };

      services.resolved.enable = true;
      systemd.services.olm = {
        description = "Pangolin Machine Client";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          EnvironmentFile = tpl."olm.env".path;
          ExecStart = lib.getExe pkgs.fosrl-olm + " --endpoint https://pangolin.theless.one";
          Type = "simple";
          Restart = "always";
        };
      };
    };
}
