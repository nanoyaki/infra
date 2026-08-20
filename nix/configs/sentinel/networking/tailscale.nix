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
        foldl'
        hasInfix
        removePrefix
        concatLines
        ;
      inherit (config) prt dmn sec;

      server = inputs.self.nixosConfigurations.thelessone.config;

      mkTailnetHosts =
        tailnetIpv4: tailnetIpv6: magicDnsBaseDomain: virtualHosts:
        foldl' (
          acc: domain:
          let
            sanitized = removePrefix "http://" (removePrefix "https://" domain);
            inTailnet = (virtualHosts.${domain}.useTailnet or false) && hasInfix magicDnsBaseDomain sanitized;
          in
          if inTailnet then
            concatLines [
              acc
              ''
                ${tailnetIpv4}  ${sanitized}
                ${tailnetIpv6}  ${sanitized}
              ''
            ]
          else
            acc
        ) "" (attrNames virtualHosts);

      sentinelTailnetHosts =
        mkTailnetHosts "100.64.0.4" "fd7a:115c:a1e0::4" "theless.one"
          config.sentinel.caddy.host;
      thelessoneTailnetHosts =
        mkTailnetHosts "100.64.0.2" "fd7a:115c:a1e0::2" "theless.one"
          server.thelessone.caddy.vHost;

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
              "53"
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
          {
            src = [
              "contact@nanoyaki.space"
              "tag:hana"
            ];
            dst = [ "autogroup:internet" ];
            via = [ "tag:exit" ];
            ip = [ "*" ];
          }
        ];

        tagOwners = {
          "tag:exit" = [ ];
          "tag:server" = [ ];
          "tag:hana" = [ "contact@nanoyaki.space" ];
        };

        autoApprovers.exitNode = [ "tag:exit" ];

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
          "--advertise-exit-node"
        ];
      };

      systemd.services.tailscaled-autoconnect.postStart = ''
        ${pkgs.ethtool}/sbin/ethtool -K ens6 rx-udp-gro-forwarding on rx-gro-list off
      '';

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
            magic_dns = false;
            override_local_dns = false;
            nameservers.split."theless.one" = [
              "fd7a:115c:a1e0::4"
              "100.64.0.4"
            ];
          };
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 53 ];
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 53 ];
      services.coredns.enable = true;
      services.coredns.extraArgs = [ "-dns.port=53" ];
      services.coredns.config = ''
        theless.one {
          bind 0.0.0.0 :: {
            except 85.215.152.236 2a01:239:454:9300::1
          }

          hosts {
            ${sentinelTailnetHosts}
            ${thelessoneTailnetHosts}
            fallthrough
          }

          forward . 2620:fe::fe 2620:fe::9 9.9.9.9 149.112.112.112 {
            tls_servername dns.quad9.net
            health_check 5s
          }

          log
          errors
        }

        . {
          bind 0.0.0.0 :: {
            except 85.215.152.236 2a01:239:454:9300::1
          }

          forward . 2620:fe::fe 2620:fe::9 9.9.9.9 149.112.112.112 {
            tls_servername dns.quad9.net
            health_check 5s
          }

          cache 300
          log
          errors
        }
      '';

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
