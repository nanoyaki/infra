{
  flake.nixosModules.thelessone-dns = {
    programs.dnscontrol.credentials.porkbun-thelessone = {
      type = "porkbun";
      api_key = "PORKBUN_API_KEY_THELESSONE";
      secret_key = "PORKBUN_SECRET_API_KEY_THELESSONE";
    };

    programs.dnscontrol.domains."theless.one" = {
      provider = "porkbun-thelessone";
      registrar = "porkbun-thelessone";

      alias."@".value = "ao4s0dnu2d2vzzc6.myfritz.net.";
      alias."*".value = "ao4s0dnu2d2vzzc6.myfritz.net.";
      cname.at01.value = "@";
      cname.at02.value = "@";
    };

    services.knot-resolver.enable = true;
    services.knot-resolver.settings = { };
    services.resolved.enable = false;
  };
}
