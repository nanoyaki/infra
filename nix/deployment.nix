{
  perSystem =
    { pkgs, ... }:

    {
      packages.deploy = pkgs.writeShellApplication {
        name = "deploy";
        runtimeInputs = with pkgs; [
          nix
          nix-output-monitor
        ];

        text = ''
          set -eo pipefail

          TARGET_SYSTEM="$1"
          NIX_CONFIG="''${NIX_CONFIG:+"$NIX_CONFIG\n"}extra-experimental-features = nix-command flake"

          if [ -z "$TARGET_SYSTEM" ]; then
            echo "Usage: deploy [target system]"
            exit 1
          fi

          # Impure is necessary since we are accessing an unlocked reference here
          TARGET_HOST="$(
            nix eval \
              --raw \
              --expr "
                let 
                  flake = (builtins.getFlake (builtins.toString ./.)).nixosConfigurations.$TARGET_SYSTEM.config;
                in

                flake.networking.fqdn or flake.networking.domain
              " \
              --impure
          )"

          BUILT_SYSTEM="$(
            nom build \
              ".#nixosConfigurations.$TARGET_SYSTEM.config.system.build.toplevel" \
              --no-link --print-out-paths
          )"

          echo "Reminder: no-check-sigs is on. Make sure to fix this one day"
          nix copy \
            "$BUILT_SYSTEM" \
            --to "ssh://root@$TARGET_HOST" \
            --no-check-sigs

          # shellcheck disable=SC2029
          ssh "root@$TARGET_HOST" "
            nix-env -p /nix/var/nix/profiles/system --set \"''${BUILT_SYSTEM}\" \
            && \"''${BUILT_SYSTEM}/bin/switch-to-configuration\" boot \
            && \"''${BUILT_SYSTEM}/bin/switch-to-configuration\" switch
          "
        '';
      };
    };
}
