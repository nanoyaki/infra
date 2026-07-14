{
  flake.nixosModules.tubaki-dns =
    { lib, ... }:

    let
      inherit (lib) singleton;
    in

    {
      programs.dnscontrol.credentials = {
        porkbun = {
          type = "porkbun";
          api_key = "PORKBUN_API_KEY";
          secret_key = "PORKBUN_SECRET_API_KEY";
        };

        porkbun-thelessone = {
          type = "porkbun";
          api_key = "PORKBUN_API_KEY_THELESSONE";
          secret_key = "PORKBUN_SECRET_API_KEY_THELESSONE";
        };

        porkbun-aslija = {
          type = "porkbun";
          api_key = "PORKBUN_API_KEY_ASLIJA";
          secret_key = "PORKBUN_SECRET_API_KEY_ASLIJA";
        };
      };

      programs.dnscontrol.domains = {
        "nanoyaki.space" = {
          registrar = "porkbun";
          provider = "porkbun";

          a.mail.address = "31.70.93.127";
          aaaa.mail.address = "2a01:239:43e:2c00::1";
          cname.autoconfig.value = "discover";
          cname.autodiscover.value = "discover";
          cname.de02.value = "mail";

          cname.imap.value = "mail";
          cname.smtp.value = "mail";

          dkim = singleton {
            selector = "mail";
            keytype = "rsa";
            pubkey = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1Nfwq2ti9zl8umzXPkIe0vDinilVejz161NeTlwaPjoI27bO2suUJeO3y6uGS8/+WuSxfpoA8Si/lpCPRbEgxtnqn8c9d3NgacJ2ntuHbbgurTa5xHk92LuONIzizBFYVy2Ftb1fBKjqkem95S9uK7NOo9gWOXnYDBYlT0wACCakrv0k2GfPNJudbQFOft0vHC+WydhQFDPuJh9d/Y7YttkRw3dQFwTEo4CLJr6ctguZCr3qf1bjPz9/UIwTVDH9LZse5t0PeHWxiYnkcb40K/L8lJ7d7Lkd40YO3HzwmOpOb/vCUnT7KxUQYjEORLrp58BydR6sJmri80BdmQLtlDu4y9LZp8oBYsipqkUKiV4Rq0psOs4ytjss3NHkFaXnO4aYdjZHSdMJP3WfyxR08QMB70RCHlwvr5R/MIgfyVk89FQsTjNPokVRTSUp8XuFTTg8p9j4nW4Bf7SaFcYOc88GjtdHHQtg1SqDeVZHzUI4Tk23ywDVT0+YWC6r1FPzncYUq/djzDLK+K8NPw7cSInf4bTo+9AHFjWoFM4TOl8xXugS/wZ4HUkUiAQ8CdWxhkpOaEmZYZCzu3kQG0Le1ovYgBzLGZ3PzgFXucN68A4A09Io/RYhNzmsqVbAuU6POY/6hapaNn3sEdFRMIvvtginzfAS7TGSRnARWLplYOsCAwEAAQ==";
          };

          dmarc = singleton {
            policy = "reject";
            alignmentSPF = "strict";
            alignmentDKIM = "strict";
          };

          spf = singleton {
            parts = [
              "v=spf1"
              "mx"
              "~all"
            ];
          };

          mx = singleton {
            subdomain = "@";
            priority = 10;
            value = "mail";
          };
        };

        "hanakretzer.de" = {
          registrar = "porkbun";
          provider = "porkbun";

          a.vpn.address = "100.64.0.11";
          cname.mail.value = "mail.nanoyaki.space.";
          cname.autoconfig.value = "discover.nanoyaki.space.";
          cname.autodiscover.value = "discover.nanoyaki.space.";
          cname.de02.value = "mail.nanoyaki.space.";
          cname.zuhause.value = "vpn";

          cname.imap.value = "mail";
          cname.smtp.value = "mail";

          mx = singleton {
            subdomain = "@";
            value = "mail.nanoyaki.space.";
            priority = 10;
          };

          dkim = singleton {
            selector = "mail";
            pubkey = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA2B9qdqjfjt2rRjvSZAfW8OusCAd86cCqtDBPI4Txu1lBbHeNVpheFfifYv1S0i7cb7AAN7UIITbz1UlM7lM5uQKjRoVKqlxypHMs2nbJLOpZKVEwZ/eu/e5guDqbLmwcUZ4FkoGbFsDXw+s64SaWfaSkNpMBxX49HI3dPtgTZahxDLrx1t+8t5kVw+/u0W7YvSN0auEkaa6pCZrPZk7bDce0/OVHY/GsUzzo1X9jPRAWXwsXs/14N+5hXX6z5REau4lubwoY20ENV0My5uT7GsnnYnXPAtG9s2UgJgbQuTmRl/qXUYGgP6XU+SpUa4fanYptq/Kqdl+gepyu/uhVX2x9aLzYk808vRbbK6McHcX7rtekWSaqxs8BUx37/8clmftpaZx1iPjOHtmmD11Z8I4Njo8I4rG+92SRIfDAIeaxyWQnV3v2HMYRKlLqTHXDiq51jud89nrpciE0YUGywxgWjH4R2f68xRVhxPxc/nDTUub19pMggQKsHSUedIuypYgbPTwonnMivKy/k44ls9yZ3HwzUVs8XRaf+ubyBoqWp2BlKugkXWRBid+FASZXqug/kghCJSv37ff9kDc9mdmGm212FQvg6Jc08WNtpe9ZuXMaSn1p7fpgAJp6AEHsaaRUgDjBSPqL/zQtPLWLol/ZlMohLRyjd2YJZ1aAdikCAwEAAQ==";
            keytype = "rsa";
          };

          dmarc = singleton {
            policy = "reject";
            alignmentSPF = "strict";
            alignmentDKIM = "strict";
          };

          spf = singleton {
            parts = [
              "v=spf1"
              "mx"
              "~all"
            ];
          };
        };

        "theless.one" = {
          registrar = "porkbun-thelessone";
          provider = "porkbun-thelessone";

          cname.mail.value = "mail.nanoyaki.space.";
          cname.autoconfig.value = "discover.nanoyaki.space.";
          cname.autodiscover.value = "discover.nanoyaki.space.";
          cname.de03.value = "mail.nanoyaki.space.";

          cname.imap.value = "mail";
          cname.smtp.value = "mail";

          mx = singleton {
            subdomain = "@";
            value = "mail.nanoyaki.space.";
            priority = 10;
          };

          dkim = singleton {
            selector = "mail";
            pubkey = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5MWwG7Tlj67eoXUI7X9tV5XSovkBP0KiFth/j+8UgceH8Oa9sM2bMqBWHnDBJh+FBEavLchthChN/e/6tPqksdf7uWU/vxs2H/bamteS0THwfQ7cA5P95ZDh5xWRJq1ixurxuI0mDqsngoFE/b0nzpuB9rJDUTV5nhAcXlyaGV/I8HS+8G89ZWQM9tygbAwru cj7qu3fl8dEDesqXhJAZ2DWAokRELDhq69EdUQ0WalLeGqVAR5o0NuSZmN4mETfxKUim/9kgle2gQV1Q58ymZELj3fCURjrfFvzgCs8+DVSbvVjnzx9x/mlQe40xRL2AGKDulQL1UXjuEDbY6nTs9/Sp5L3EAZZtInmfJJpCq42fGN+jfMN5wbTfGKCPmSdLd+BphAz2JgP7UfI67nfnfS1W6ENkSvmCeTK8v/PXH5GaIevuFaZK40iDVyNvbao X5USTaFCF09mpncWwpCQFPjOmr+rblGheO+sSRYgyd9ImDAf8uhX7dtW6DqNc7CwaeUoNw6d5b14jv7VLmcYAXmqnpszqNONf0fx/LxTGLdsZPzFgrIbXP3q8zQSpJJxDr2yK/phA5D3Hp5TQjrtuUxltIhQDQARb6iRY+e2XFbEC8yZiT0RQ3HwPc5GQURVsRxJfZtZ1U51HxbcO3qm6x9XgnJuqHXwin1W5Xo68UcCAwEAAQ==";
            keytype = "rsa";
          };

          dmarc = singleton {
            policy = "reject";
            alignmentSPF = "strict";
            alignmentDKIM = "strict";
          };

          spf = singleton {
            parts = [
              "v=spf1"
              "mx"
              "~all"
            ];
          };
        };

        "aslija.com" = {
          registrar = "porkbun-aslija";
          provider = "porkbun-aslija";

          a."@".address = "31.70.93.127";
          aaaa."@".address = "2a01:239:43e:2c00::1";
          cname.mail.value = "mail.nanoyaki.space.";
          cname.autoconfig.value = "discover.nanoyaki.space.";
          cname.autodiscover.value = "discover.nanoyaki.space.";

          cname.imap.value = "mail";
          cname.smtp.value = "mail";

          mx = singleton {
            subdomain = "@";
            value = "mail.nanoyaki.space.";
            priority = 10;
          };

          dkim = singleton {
            selector = "mail";
            pubkey = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAsbyNtrAAUSoTgMeh+VFj+MEpWiSpITSeRrM7A8oC5iBeyVtG6zx4DNQRepSkSY79+dzAH+xaJ4YnZ5qdkeA7MxVGmNxfQbZ3n3lXTmwRwkwslUGxE1gE3pzB92cosoVeCgsiBk8OTdlfcxWv+yPNS2PMJ2KDpidSg8GOPXd6kLhHuoLZ9AZjPXBAgJGJ/dfQBKYHlaNYcXdEokjzJ8x1KPOmaph+0dOX5adI4dAXyuIUAuZ0+MGBd0RscziLWzwPSPqwtD9CmZnGwax89kSkOEm28avv4hbzxco5RlCqeg5zi5pdwxz1j96cFxAt+pfKXVijnu7BMceRqCcFEOKRzvGBCdgNIj3lpmqj12Qtezfvk+HsADjwlhmelIncw34ZJ8zeNfRpXJ1WZSzViByU1+rlknptvrXQrrkaowwq8a7063i7R3APWsoigpIZ+5W6yAziEsHdldJRnJfEirNCA+5mGSvvTOIKn3VFAe2GLKN7CQNfd7jwM+Rs0QHl5UkNp4iUD1BqCYbB4W/7vhdIldE4Q+IvH5WKkQlfH0DI/ecFfyzaBApXU8vBngxHq2BCPbojhd4/eb1ky9bsl3tKxa8tORF7H5t39qvzRcmqFRnvXf3/5IkoGvLqfFlQWlGgO/e4lwdYJuMCmbmJGDlVSJlMtCjnUt9EqMra2FL8hTcCAwEAAQ==";
            keytype = "rsa";
          };

          dmarc = singleton {
            policy = "reject";
            alignmentSPF = "strict";
            alignmentDKIM = "strict";
          };

          spf = singleton {
            parts = [
              "v=spf1"
              "mx"
              "~all"
            ];
          };
        };
      };
    };
}
