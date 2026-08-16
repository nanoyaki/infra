{ inputs, ... }:

{
  flake.nixosModules.thelessone-valheim =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config) plh tpl;
    in

    {
      imports = [ inputs.valheim-server.nixosModules.default ];

      sec.valheim-password = { };
      tpl."valheim-password.env".file = pkgs.writeEnv "valheim-password.env.template" {
        VH_SERVER_PASSWORD = plh.valheim-password;
      };

      systemd.services.valheim.wantedBy = lib.mkForce [ "server-services.target" ];
      services.valheim = {
        enable = true;
        openFirewall = true;
        passwordEnvFile = tpl."valheim-password.env".path;

        noGraphics = true;
        public = true;
        serverName = "LSQ Gaming";
        worldName = "pre-v1";
        adminList = [ "76561198294979887" ];
      };

      # Turn off the server for a few weeks
      systemd.services.valheim.enable = false;

      programs.dnscontrol.domains."theless.one" = {
        srv = [
          {
            service = "valheim";
            protocol = "tcp";
            subdomain = "valheim";
            inherit (config.services.valheim) port;
            target = "at01.theless.one.";
          }
        ];
      };

      thelessone.backups.valheim.paths = [
        "/var/lib/valheim/.config/unity3d/IronGate/Valheim/worlds_local"
      ];

      nixpkgs.allowUnfreeNames = [
        "steamworks-sdk-redist"
        "valheim-server"
      ];
    };
}
