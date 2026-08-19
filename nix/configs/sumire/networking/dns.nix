{
  flake.nixosModules.sumire-dns =
    _:

    {
      programs.dnscontrol.credentials.porkbun = {
        type = "porkbun";
        api_key = "PORKBUN_API_KEY";
        secret_key = "PORKBUN_SECRET_API_KEY";
      };

      programs.dnscontrol.domains."serdexmethylpheni.date" = {
        registrar = "porkbun";
        provider = "porkbun";

        a."@".address = "5.175.180.4";
        aaaa."@".address = "2a0f:6284:4300:101::110d";
        cname.de01.value = "@";
        cname."turn".value = "@";
        cname."id".value = "@";
        cname."rtc".value = "@";
      };
    };
}
