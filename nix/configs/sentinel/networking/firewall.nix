{
  flake.nixosModules.sentinel-firewall =
    _:

    {
      # Tunneled ports
      networking.firewall.allowedTCPPorts = [
        993 # IMAP
        465 # SMTP
        22 # Forgejo SSH

        25565 # Minecraft
        7777 # SCP:SL
        2456 # Valheim
      ];

      services.traefik.staticConfigOptions.entryPoints = {
        tcp-993.address = ":993/tcp";
        tcp-465.address = ":465/tcp";
        tcp-22.address = ":22/tcp";

        tcp-25565.address = ":25565/tcp";
        tcp-7777.address = ":7777/tcp";
        tcp-2456.address = ":2456/tcp";
      };
    };
}
