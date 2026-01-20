{
  lib,
  pkgs,
  config,
  ...
}:

let
  writeEnv = (pkgs.formats.keyValue { }).generate;
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

      postRun = ''
        set -x

        ${lib.getExe pkgs.rsync} -avz --delete \
          -e "ssh -i ${config.sops.secrets.id_acme_thelessone.path}" \
          ${config.security.acme.certs."theless.one".directory} \
          acme@100.64.64.1:${config.security.acme.certs."theless.one".directory}
      '';
    };
  };
}
