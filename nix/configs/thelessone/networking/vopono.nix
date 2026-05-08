{ inputs, ... }:

{
  flake.nixosModules.thelessone-vopono =
    { lib, config, ... }:

    {
      imports = [ inputs.nanomodules.nixosModules.vopono ];

      sops.secrets = {
        wireguard-private = { };
        wireguard-address = { };
        wireguard-public = { };
        wireguard-endpoint = { };
      };

      sops.templates."wireguard.conf" = {
        owner = "vopono";
        restartUnits = [ "vopono.service" ];
        content = with config.sops.placeholder; ''
          [Interface]
          PrivateKey = ${wireguard-private}
          Address = ${wireguard-address}
          DNS = 10.64.0.1

          [Peer]
          PublicKey = ${wireguard-public}
          AllowedIPs = 0.0.0.0/0,::0/0
          Endpoint = ${wireguard-endpoint}
        '';
      };

      systemd.services.vopono.wantedBy = lib.mkForce [ "server-services.nix" ];
      services.vopono = {
        enable = true;

        interface = "enp9s0";
        configFile = config.sops.templates."wireguard.conf".path;
        protocol = "Wireguard";
        namespace = "vp0";
      };
    };
}
