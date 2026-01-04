{
  lib,
  pkgs,
  config,
  ...
}:

{
  sops.secrets = {
    "dynamicdns/vappie.space" = { };
    "porkbun/api-key" = { };
    "porkbun/secret-api-key" = { };
    "porkbun-nano/api-key" = { };
    "porkbun-nano/secret-api-key" = { };
  };

  config'.dynamicdns.enable = true;
  config'.dynamicdns.domains."vappie.space" = {
    subdomains = [
      "*"
      "@"
    ];

    passwordFile = config.sops.secrets."dynamicdns/vappie.space".path;
  };

  sops.templates."oink.json".file = (pkgs.formats.json { }).generate "oink.json" {
    global = {
      secretapikey = config.sops.placeholder."porkbun/secret-api-key";
      apikey = config.sops.placeholder."porkbun/api-key";
      interval = 900;
      ttl = 600;
    };

    domains = [
      {
        domain = "nanoyaki.space";
        subdomain = "";
      }
      {
        domain = "nanoyaki.space";
        subdomain = "*";
      }
    ]
    ++
      map
        (subdomain: {
          domain = "theless.one";
          inherit subdomain;
        })
        [
          "*"
          ""
          "mail"
        ];
  };

  systemd.services.oink = {
    description = "Dynamic DNS client for Porkbun";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.oink} -c ${config.sops.templates."oink.json".path} -v";
      Restart = "always";
      Type = "simple";
    };
  };

  sops.templates."theless.one.acme.env".file = (pkgs.formats.keyValue { }).generate "acme.env" {
    PORKBUN_API_KEY = config.sops.placeholder."porkbun/api-key";
    PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun/secret-api-key";
  };

  sops.templates."nanoyaki.space.acme.env".file = (pkgs.formats.keyValue { }).generate "acme.env" {
    PORKBUN_API_KEY = config.sops.placeholder."porkbun-nano/api-key";
    PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun-nano/secret-api-key";
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      inherit (config.services.caddy) group;
      email = "contact@nanoyaki.space";

      dnsProvider = "porkbun";
      dnsResolver = "173.245.58.37:53";
      dnsPropagationCheck = true;
    };

    certs."theless.one" = {
      environmentFile = config.sops.templates."theless.one.acme.env".path;
      extraDomainNames = [
        "*.vpn.theless.one"
        "*.theless.one"
      ];
    };

    certs."nanoyaki.space" = {
      environmentFile = config.sops.templates."nanoyaki.space.acme.env".path;
      extraDomainNames = [ "*.nanoyaki.space" ];
    };
  };
}
