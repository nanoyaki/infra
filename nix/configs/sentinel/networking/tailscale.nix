{ inputs, ... }:

{
  flake.nixosModules.sentinel-tailscale =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib)
        attrNames
        filter
        foldl'
        optionals
        hasInfix
        removePrefix
        concatLines
        ;
      inherit (config) prt dmn sec;

      server = inputs.self.nixosConfigurations.thelessone.config;

      mkUnknownIp =
        magicDnsBaseDomain: virtualHosts:
        filter (
          domain: (!(virtualHosts.${domain}.useTailnet or false)) && hasInfix magicDnsBaseDomain domain
        ) (attrNames virtualHosts);
      mkTailnetHosts =
        magicDnsBaseDomain: tailnetIpv4: tailnetIpv6: virtualHosts:
        foldl' (
          acc: domain:
          let
            records = [
              {
                name = domain;
                type = "A";
                value = tailnetIpv4;
              }
              {
                name = domain;
                type = "AAAA";
                value = tailnetIpv6;
              }
            ];
          in
          acc
          ++ (optionals (
            (virtualHosts.${domain}.useTailnet or false) && hasInfix magicDnsBaseDomain domain
          ) records)
        ) [ ] (attrNames virtualHosts);

      # this is silly, lol
      unknownIps = concatLines (
        map (removePrefix "https://") (
          map (removePrefix "http://") (mkUnknownIp "theless.one" server.thelessone.caddy.vHost)
        )
      );

      sentinelTailnet =
        mkTailnetHosts "theless.one" "100.64.0.4" "fd7a:115c:a1e0::4"
          config.sentinel.caddy.host;
      thelessoneTailnet =
        mkTailnetHosts "theless.one" "100.64.0.2" "fd7a:115c:a1e0::2"
          server.thelessone.caddy.vHost;

      defaultExtraRecords = (pkgs.formats.json { }).generate "default-extra-records.json" (
        sentinelTailnet ++ thelessoneTailnet
      );

      policyJson = (pkgs.formats.json { }).generate "policy.json" {
        grants = [
          {
            src = [ "autogroup:member" ];
            dst = [ "autogroup:self" ];
            ip = [ "*" ];
          }
          {
            src = [ "autogroup:member" ];
            dst = [ "tag:server" ];
            ip = [
              "443"
              "80"
            ];
          }
          {
            src = [
              "contact@nanoyaki.space"
              "tag:hana"
            ];
            dst = [ "tag:hana" ];
            ip = [ "*" ];
          }
        ];

        tagOwners = {
          "tag:server" = [ ];
          "tag:hana" = [ "contact@nanoyaki.space" ];
        };

        nodeAttrs = [
          {
            target = [ "*" ];
            attr = [ "magicdns-aaaa" ];
          }
        ];
      };
    in

    {
      disabledModules = [ "services/networking/headplane.nix" ];
      imports = [ inputs.headplane.nixosModules.headplane ];

      sec = with config.services.headscale; {
        "headscale/oidc-secret".owner = user;
        "headplane/api-key".owner = user;
        "headplane/oidc-secret".owner = user;
        "headplane/cookie-secret".owner = user;
        tailscale = { };
      };

      prt.headscale = 8004;
      prt.headplane = 8005;

      dmn.headscale = "headscale.nanoyaki.space";
      dmn.headplane = "headplane.nanoyaki.space";

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "server";
        authKeyFile = config.sec.tailscale.path;
        extraUpFlags = [
          "--login-server=https://${dmn.headscale}"
          "--force-reauth"
          "--accept-dns=true"
        ];
      };

      systemd.services.headscale-records = {
        wantedBy = [ "headscale.service" ];

        path = with pkgs; [
          jq
          dig
        ];
        script = ''
          domains=(
            ${unknownIps}
          )

          resolve() {
            dig @9.9.9.9 +short -t "$2" "$1" | tail -n 1 | tr -d '\n'
          }

          records_file="$(mktemp)"
          for domain in "''${domains[@]}"; do
            [ -z "$domain" ] && continue
            ipv4="$(resolve "$domain" "A")"
            ipv6="$(resolve "$domain" "AAAA")"
            
            jq -n --arg name "$domain" --arg value "$ipv4" \
              '{name: $name, type: "A", value: $value}' >> "$records_file"
            jq -n --arg name "$domain" --arg value "$ipv6" \
              '{name: $name, type: "AAAA", value: $value}' >> "$records_file"
            echo "Processed: $domain ($ipv4 $ipv6)"
          done

          jq -s -r --slurpfile defaults "${defaultExtraRecords}" \
            '($defaults[] + .) | sort_by(.name, .type, .value)' \
            "$records_file" > /var/lib/headscale-records/records.json

          echo "Successfully created the record file!"
        '';

        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "headscale-records";
          UMask = "0027";
          User = config.services.headscale.user;
          Group = config.services.headscale.group;
        };

        restartTriggers = [ defaultExtraRecords ];
      };

      systemd.timers.headscale-records.wantedBy = [ "timers.target" ];
      systemd.timers.headscale-records.timerConfig.OnCalendar = "*/5 * * * *";

      environment.etc."headscale/policy.json".source = policyJson;
      systemd.services.headscale.reloadTriggers = [ policyJson ];
      services.headscale = {
        enable = true;

        address = "127.0.0.1";
        port = prt.headscale;

        settings = {
          server_url = "https://${dmn.headscale}";

          prefixes.v4 = "100.64.0.0/10";
          prefixes.v6 = "fd7a:115c:a1e0::/48";

          policy.path = "/etc/headscale/policy.json";

          node.expiry = 0;
          oidc = {
            issuer = "https://${server.dmn.pocket-id}";
            client_id = "8d80ec56-c0d9-45ef-8ebb-7abd0c708e76";
            client_secret_path = sec."headscale/oidc-secret".path;
            pkce.enabled = true;
            pkce.method = "S256";

            scope = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
          };

          dns = {
            magic_dns = true;
            base_domain = "theless.one";

            override_local_dns = true;
            nameservers.global = [
              "1.1.1.1"
              "1.0.0.1"
            ];

            extra_records_path = "/var/lib/headscale-records/records.json";
          };
        };
      };

      services.headplane = {
        enable = true;

        settings = {
          server = {
            base_url = "https://${dmn.headplane}";
            port = prt.headplane;
            cookie_secret_path = sec."headplane/cookie-secret".path;
          };

          headscale = {
            url = "https://${dmn.headscale}";
            config_path = config.services.headscale.configFile;
            api_key_path = sec."headplane/api-key".path;
          };

          oidc = {
            issuer = "https://${server.dmn.pocket-id}";
            client_id = "e9368c4e-fa05-4cf8-83c8-04555cb3e1ce";
            client_secret_path = sec."headplane/oidc-secret".path;
            disable_api_key_login = true;
            use_pkce = true;
          };
        };
      };

      sentinel.caddy.host.${dmn.headscale}.proxy.port = prt.headscale;
      sentinel.caddy.host.${dmn.headplane} = {
        proxy.port = prt.headplane;
        config = ''
          redir / /admin
        '';
      };
    };
}
