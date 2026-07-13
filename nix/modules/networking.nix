{
  flake.nixosModules.networking =
    { lib, config, ... }:

    let
      inherit (lib)
        mkOption
        types
        mkForce
        mkDefault
        attrValues
        unique
        foldl
        literalExpression
        ;
    in

    {
      options = {
        prt = mkOption {
          type = types.submodule {
            freeformType = types.attrsOf types.port;

            options.free = mkOption {
              type = types.port;
              default =
                let
                  all = attrValues (removeAttrs config.prt [ "free" ]);
                in
                (foldl (
                  highest: port: if port > highest && port >= 8000 && port < 8090 then port else highest
                ) 7999 all)
                + 1;
              readOnly = true;
            };
          };
          default = { };
          example = literalExpression ''
            {
              service = ${toString config.prt.free};
            }
          '';
        };

        dmn = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = literalExpression ''
            {
              service = "example.com";
            }
          '';
        };
      };

      config = {
        assertions = [
          {
            assertion =
              let
                ports = attrValues config.prt;
              in
              ports == unique ports;
          }
        ];

        prt = {
          http = mkForce 80;
          https = mkForce 443;
          imap = mkForce 143;
          imap-tls = mkForce 993;
          smtp = mkForce 25;
          smtp-tls = mkForce 465;
          smtp-starttls = mkForce 587;
          ssh = mkForce 22;
          nntps = mkForce 563;
          nfs = mkForce 2049;
          manage-sieve = mkForce 4190;
        };

        networking = {
          nftables.enable = true;
          firewall.enable = true;
          useDHCP = mkDefault true;

          nameservers = mkDefault [
            "1.1.1.1"
            "1.0.0.1"
            "8.8.8.8"
            "8.8.4.4"
          ];
        };
      };
    };
}
