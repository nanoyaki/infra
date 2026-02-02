{
  flake.nixosModules.thelessone-nonNixMinecraft =
    { lib, pkgs, ... }:

    let
      socket = "/run/non-nix-minecraft/servers.sock";
      dataDir = "/srv/non-nix-minecraft";

      java =
        version:

        let
          pkg = pkgs."zulu${toString version}";
        in

        pkgs.writeShellScriptBin "java${toString version}" ''
          JAVA_HOME="${pkg.home}" ${lib.getExe' pkg "java"}
        '';
    in

    {
      users.users.thelessone.extraGroups = [ "non-nix-minecraft" ];
      users.groups.non-nix-minecraft = { };
      users.users.non-nix-minecraft = {
        isSystemUser = true;
        group = "non-nix-minecraft";
        homeMode = "770";
        home = dataDir;
        createHome = true;

        packages = [
          (pkgs.writeShellScriptBin "java" ''
            JAVA_HOME=${pkgs.zulu21.home} ${lib.getExe pkgs.zulu21} "$@"
          '')
          (java 21)
          (java 17)
          (java 8)
        ];
      };

      systemd.services.non-nix-minecraft-servers = {
        enable = true;
        description = "Non-Nix Minecraft server autostart";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        path = with pkgs; [
          tmux
          coreutils
        ];
        script = ''
          set -x

          MINECRAFT_SERVERS="$(find ${dataDir}/. -maxdepth 1 -type d -not -name '.*' -printf '%f\n')"
          [[ -z "$MINECRAFT_SERVERS" ]] && exit 0

          for server in $MINECRAFT_SERVERS; do
            [[ -f "${dataDir}/$server/run.sh" ]] \
              && chmod 750 "${dataDir}/$server/run.sh"

            tmux -S ${socket} new -s "$server" -d bash -c 'sh ${dataDir}/'"$server"'/run.sh; exec bash'
            tmux -S ${socket} server-access -aw nobody
          done
        '';
        postStart = ''
          set -x

          [[ -f ${socket} ]] && chmod 660 ${socket}
        '';

        serviceConfig = {
          Type = "oneshot";

          User = "non-nix-minecraft";
          Group = "non-nix-minecraft";

          TimeoutStopSec = "1min 15s";
          WorkingDirectory = dataDir;

          RuntimeDirectory = "non-nix-minecraft";
          RuntimeDirectoryPreserve = "yes";

          CapabilityBoundingSet = [ "" ];
          DeviceAllow = [ "" ];
          LockPersonality = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          UMask = "0007";
        };
      };

      networking.firewall = {
        allowedTCPPortRanges = [
          {
            from = 25566;
            to = 25575;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 25566;
            to = 25575;
          }
        ];
      };
    };
}
