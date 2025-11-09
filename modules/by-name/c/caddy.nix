{
  lib,
  lib',
  config,
  pkgs,
  ...
}:

let
  inherit (lib'.options)
    mkDefault
    mkAttrsOf
    mkNullOr
    mkListOf
    mkTrueOption
    mkFalseOption
    mkPortOption
    mkSubmoduleOption
    mkStrOption
    mkPathOption
    ;

  inherit (lib)
    mkIf
    mkRenamedOptionModule
    elemAt
    ;
  inherit (lib.strings)
    optionalString
    hasInfix
    hasPrefix
    removeSuffix
    splitString
    ;
  inherit (lib.attrsets)
    filterAttrs
    nameValuePair
    mapAttrs'
    ;

  cfg = config.config'.caddy;

  deprecatedPath = [
    "config'"
    "caddy"
    "reverseProxies"
  ];
  vHostPath = [
    "config'"
    "caddy"
    "vHost"
  ];

  mkVHostRenamedOpt =
    oldPath: newPath: mkRenamedOptionModule (deprecatedPath ++ oldPath) (vHostPath ++ newPath);

  enabledHosts = filterAttrs (_: hostCfg: hostCfg.enable) cfg.vHost;
in

{
  options.config'.caddy = {
    enable = mkFalseOption;

    openFirewall = mkFalseOption;
    baseDomain = mkStrOption;
    email = mkDefault "hanakretzer@gmail.com" mkStrOption;
    porkbunCreds = mkPathOption;
    vpnServerV4 = mkDefault "100.64.64.1" mkStrOption;
    vpnServerV6 = mkDefault "fd64::1" mkStrOption;

    vHost = mkAttrsOf (mkSubmoduleOption {
      enable = mkTrueOption;
      proxy = {
        port = mkPortOption;
        host = mkDefault "localhost" mkStrOption;
      };
      userEnvVar = mkNullOr mkStrOption;
      extraConfig = mkStrOption;
      serverAliases = mkListOf mkStrOption;
      useVpn = mkFalseOption;
    });
  };

  imports = [
    (mkVHostRenamedOpt [ "port" ] [ "proxy" "port" ])
    (mkVHostRenamedOpt [ "host" ] [ "proxy" "host" ])
    (mkVHostRenamedOpt [ "enable" ] [ "enable" ])
    (mkVHostRenamedOpt [ "userEnvVar" ] [ "userEnvVar" ])
    (mkVHostRenamedOpt [ "extraConfig" ] [ "extraConfig" ])
    (mkVHostRenamedOpt [ "serverAliases" ] [ "serverAliases" ])
    (mkVHostRenamedOpt [ "vpnOnly" ] [ "useVpn" ])
  ];

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      80
      443
    ];

    services.caddy = {
      enable = true;
      enableReload = true;
      inherit (cfg) email;

      logFormat = ''
        format console
        level INFO
      '';

      extraConfig = ''
        (error_handling) {
          handle_errors {
            root * ${pkgs.error-pages}/share/error-pages
            rewrite * /{http.error.status_code}.html
            file_server
          }
        }
      '';

      virtualHosts = mapAttrs' (
        domain: vhost:
        nameValuePair domain {
          extraConfig = ''
            ${optionalString (vhost.userEnvVar != null) ''
              basic_auth * {
                {''$${vhost.userEnvVar}}
              }
            ''}

            ${vhost.extraConfig}

            ${optionalString (
              vhost.proxy.port != 0
            ) "reverse_proxy ${vhost.proxy.host}:${toString vhost.proxy.port}"}

            import error_handling
          '';
          inherit (vhost) serverAliases;
          useACMEHost = mkIf (hasInfix cfg.baseDomain domain) cfg.baseDomain;
          listenAddresses = mkIf vhost.useVpn (
            map (
              cidrSuffixed:

              let
                address = elemAt (splitString "/" cidrSuffixed) 0;
              in

              if hasInfix ":" address then "[${address}]" else address
            ) config.networking.wg-quick.interfaces.wg0.address
          );
        }
      ) enabledHosts;
    };

    systemd.services.porkbun-vpn-records = {
      description = "Create Porkbun records for VPN only endpoints";

      path = with pkgs; [
        jq
        curl
      ];
      script = ''
        is_successful() {
          local response="''${1:-'{ "status": "ERROR" }'}"
          echo "$response" | jq -r '.status == "SUCCESS"'
        }

        has_valid_record() {
          local response="''${1:-'{ "records": [ ] }'}"
          echo "$response" | jq -r '
            .records[0]
            | .content == ({ A: "${cfg.vpnServerV4}", AAAA: "${cfg.vpnServerV6}" }[.type])
          '
        }

        has_empty_record() {
          local response="''${1:-'{ "records": [ ] }'}"
          echo "$response" | jq -r '.records == [ ]'
        }

        update_record() {
          local domain="$1"
          local subdomain="$2"
          local type="$3"

          local response
          response="$(curl -L \
            -H "Content-Type: application/json" \
            --data "@${cfg.porkbunCreds}" \
            "https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$domain/$type/$subdomain"
          )"

          sleep 1

          if [ "$(is_successful "$response")" == "false" ]; then
            echo "Api retrieve request was unsuccessful. Assuming API rate limited."
            return 1
          fi

          if [ "$(has_empty_record "$response")" == "true" ]; then
            create_record "$domain" "$subdomain" "$type"
          elif [ "$(has_valid_record "$response")" == "false" ]; then
            modify_record "$domain" "$subdomain" "$type"
          fi

          echo "Updated $type record for $subdomain.$domain"
          return 0
        }

        modify_record() {
          local domain="$1"
          local subdomain="$2"
          local type="$3"

          echo "Modifying record for $subdomain.$domain"

          local request_data
          request_data="$(
            jq \
              --arg t "$type" \
              -r '{
                ttl: 900,
                content: {
                  A: "${cfg.vpnServerV4}",
                  AAAA: "${cfg.vpnServerV6}"
                }[$t]
              } * .' \
              "${cfg.porkbunCreds}"
          )"

          local response
          response="$(curl -L \
            -H "Content-Type: application/json" \
            --data "$request_data" \
            "https://api.porkbun.com/api/json/v3/dns/editByNameType/$domain/$type/$subdomain"
          )"

          sleep 1

          if [ "$(is_successful "$response")" == "false" ]; then
            echo "Api edit request was unsuccessful. Assuming API rate limited."
            return 1
          fi

          return 0
        }

        create_record() {
          local domain="$1"
          local subdomain="$2"
          local type="$3"

          echo "Creating record for $subdomain.$domain"

          local request_data
          request_data="$(
            jq \
              --arg t "$type" \
              --arg s "$subdomain" \
              -r '{
                name: $s,
                type: $t,
                ttl: 900,
                content: {
                  A: "${cfg.vpnServerV4}",
                  AAAA: "${cfg.vpnServerV6}"
                }[$t]
              } * .' \
              "${cfg.porkbunCreds}"
          )"

          local response
          response="$(curl -L \
            -H "Content-Type: application/json" \
            --data "$request_data" \
            "https://api.porkbun.com/api/json/v3/dns/create/$domain"
          )"

          sleep 1

          if [ "$(is_successful "$response")" == "false" ]; then
            echo "Api create request was unsuccessful. Assuming API rate limited."
            return 1
          fi

          return 0
        }
      ''
      + lib.concatMapAttrsStringSep "\n" (
        fqdn: vhost:
        lib.optionalString
          (vhost.useVpn && hasInfix cfg.baseDomain fqdn && !(hasPrefix "http" cfg.baseDomain))
          ''
            echo "Processing records for ${fqdn}"
            update_record "${cfg.baseDomain}" "${removeSuffix ".${cfg.baseDomain}" fqdn}" "A"
            update_record "${cfg.baseDomain}" "${removeSuffix ".${cfg.baseDomain}" fqdn}" "AAAA"
          ''
      ) cfg.vHost;

      serviceConfig = {
        Restart = "no";
        Type = "oneshot";
      };
    };

    config'.caddy.vHost."localhost:3133".extraConfig = ''
      root * ${pkgs.error-pages}/share/error-pages
      file_server
    '';

    systemd.services.caddy = {
      wants = [ "porkbun-vpn-records.service" ];
      after = [ "porkbun-vpn-records.service" ];
      path = [ pkgs.nssTools ];
    };
  };
}
