{ pkgs, config, ... }:

let
  writeEnv = (pkgs.formats.keyValue { }).generate;

  syncCerts = {
    path = with pkgs; [
      rsync
      openssh
    ];

    postStop = ''
      rsync -avz --delete \
        -e "ssh -i ''$CREDENTIALS_DIRECTORY/id_acme_thelessone" \
        ${config.security.acme.certs."theless.one".directory} \
        acme@at01.theless.one:${config.security.acme.certs."theless.one".directory}
    '';

    serviceConfig.LoadCredential = [
      "id_acme_thelessone:${config.sops.secrets.id_acme_thelessone.path}"
    ];
  };
in

{
  sops = {
    secrets.id_acme_thelessone = { };

    templates."theless.one-acme.env".file = writeEnv "theless.one-acme.env.template" {
      PORKBUN_API_KEY = config.sops.placeholder."porkbun/api-key";
      PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun/secret-api-key";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      inherit (config.services.caddy) group;
      email = "contact@nanoyaki.space";
    };

    certs."theless.one" = {
      environmentFile = config.sops.templates."theless.one-acme.env".path;
      extraDomainNames = [ "*.theless.one" ];

      dnsProvider = "porkbun";
      dnsResolver = "173.245.58.37:53";
      dnsPropagationCheck = true;
    };
  };

  systemd.services."acme-theless.one" = syncCerts;
  systemd.services."acme-order-renew-theless.one" = syncCerts;
}
