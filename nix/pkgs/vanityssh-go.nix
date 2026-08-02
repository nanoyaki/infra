{
  perSystem =
    { pkgs, ... }:

    {
      # Slopware found on github
      packages.vanityssh-go = pkgs.callPackage (
        {
          buildGoModule,
          fetchFromGitHub,
        }:

        buildGoModule (finalAttrs: {
          pname = "vanityssh-go";
          version = "3f185c4e1a52fbcdd33954bd54fc9bb6b4e1fdb9";

          src = fetchFromGitHub {
            owner = "danielewood";
            repo = "vanityssh-go";
            rev = finalAttrs.version;
            hash = "sha256-Zx5Eqi4Ceb01fyA21jrBC5uAny/yxmffAZfKkUNJR+k=";
          };

          vendorHash = "sha256-5ES+SZfvVMhIMXRujtJR1TxpD1Dkt6gXnVA7mYPVfyo=";
        })
      ) { };
    };
}
