{
  config,
  ...
}:

{
  sops.secrets.wg0 = { };

  networking.wg-quick.interfaces.wg0 = {
    address = [
      "100.64.64.1/24"
      "fd64::1/64"
    ];
    listenPort = 51820;
    # Public key
    # JB0jviICHpiTm1PYjm4+FCWCPLAjU/NZBm6tRO6/XGY=
    privateKeyFile = config.sops.secrets.wg0.path;

    peers = [
      {
        publicKey = "wN5wC+zV+7yyIa4F8DxIyYWSNPgGzk9LIZmg9wABjiw=";
        allowedIPs = [
          "100.64.64.2/32"
          "fd64::2/128"
        ];
      }
      {
        publicKey = "rhOWCYUVQTGIMqbZJ1HOPRzKE7j9O2rDoj+l6EP22ns=";
        allowedIPs = [
          "100.64.64.3/32"
          "fd64::3/128"
        ];
      }
      {
        publicKey = "abs5c0AMiAxUnMe4/U98e+eWq76Ep/0X6M+tIXL6v2g=";
        allowedIPs = [
          "100.64.64.4/32"
          "fd64::4/128"
        ];
      }
      {
        publicKey = "V3rVk0GD26Hx1KdDY3xAOw3zcOxW/IL4y1MlZlkUmmM=";
        allowedIPs = [
          "100.64.64.5/32"
          "fd64::5/128"
        ];
      }
      {
        publicKey = "2jD2gXhCD70h40UGGuJxewSvJ4KutvojTFkoT3urdVs=";
        allowedIPs = [
          "100.64.64.6/32"
          "fd64::6/128"
        ];
      }
      {
        publicKey = "NnredcGA2ZvA9hpAHRarkxDgVWlJg2w2dZgHUQThMFY=";
        allowedIPs = [
          "100.64.64.7/32"
          "fd64::7/128"
        ];
      }
      {
        publicKey = "7o8uuMiSuz7hqdEMPbo1f9mciDGQ2OR3ms3P8KPdt0Y=";
        allowedIPs = [
          "100.64.64.8/32"
          "fd64::8/128"
        ];
      }
      {
        publicKey = "8Dfsb6g+w3HKnCqk/Hf/oD6nMJ2+vNPCn9JIDF1Jdlk=";
        allowedIPs = [
          "100.64.64.9/32"
          "fd64::9/128"
        ];
      }
      {
        publicKey = "mXA1A/cR4q8ScGQGrP3HtmYQHdAsOsm+6JZNyyEJh2M=";
        allowedIPs = [
          "100.64.64.10/32"
          "fd64::10/128"
        ];
      }
      {
        publicKey = "e6Tljsbi7xecHcJedb2Ol53S+WSKBT4TdmtieiaVsnc=";
        allowedIPs = [
          "100.64.64.11/32"
          "fd64::11/128"
        ];
      }
      {
        publicKey = "WuoSvbuy3JORoxG2hNvPGHnqdjhwHHLuIN/3OGocNjw=";
        allowedIPs = [
          "100.64.64.12/32"
          "fd64::12/128"
        ];
      }
      {
        publicKey = "CTr84xrlw5Uty6DFA57qppId1r84CrEApXnj684iA24=";
        allowedIPs = [
          "100.64.64.13/32"
          "fd64::13/128"
        ];
      }
      {
        publicKey = "kOTQYfbXu1BTe1euqwbpvMCWcKRwsf7q5SVvwc9wvA4=";
        allowedIPs = [
          "100.64.64.14/32"
          "fd64::14/128"
        ];
      }
      {
        publicKey = "qGBp/URd4sWxSFElseVjz4nb9z6vIMGu5/uBg+dCLCE=";
        allowedIPs = [
          "100.64.64.15/32"
          "fd64::15/128"
        ];
      }
      {
        publicKey = "39sH3nUD/i8iacdsEtqhuSGnSbXkFi9kqIGVlfbqWjo=";
        allowedIPs = [
          "100.64.64.16/32"
          "fd64::16/128"
        ];
      }
      {
        publicKey = "P2fahjhqvpkuH7JdrViC33uh5wNTxOjfTocrR9OsKAk=";
        allowedIPs = [
          "100.64.64.17/32"
          "fd64::17/128"
        ];
      }
      {
        publicKey = "xebzRJd4kSo+RYyOt1Rffqon5h/Xm02MNt0WadaJuj4=";
        allowedIPs = [
          "100.64.64.18/32"
          "fd64::18/128"
        ];
      }
      {
        publicKey = "y6A8tqZap9cMdGhEurTDLStdjE/BwcGEtksnHA5Xm08=";
        allowedIPs = [
          "100.64.64.19/32"
          "fd64::19/128"
        ];
      }
      {
        publicKey = "Hm8YfOPG+hOmHhmvF7dBKcX5+TnVPDK/PCGuo+VjUAs=";
        allowedIPs = [
          "100.64.64.20/32"
          "fd64::20/128"
        ];
      }
    ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    externalInterface = "enp5s0";
    internalInterfaces = [ "wg0" ];
  };

  networking.firewall = {
    trustedInterfaces = [ "wg0" ];
    allowedUDPPorts = [ 51820 ];
  };
}
