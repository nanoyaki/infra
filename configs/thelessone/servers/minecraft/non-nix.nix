{ pkgs, ... }:

let
  socket = "/run/non-nix-minecraft/servers.sock";
  dataDir = "/srv/non-nix-minecraft";
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
      MINECRAFT_SERVERS="$(find ${dataDir} -maxdepth 1 -type d -not -name '.*')"

      for server in $MINECRAFT_SERVERS; do
        chmod 750 "${dataDir}/$server/run.sh"

        tmux -S ${socket} new -d bash -c 'sh ${dataDir}/'"$server"'/run.sh; exec bash'
        tmux -S ${socket} server-access -aw nobody
      done
    '';
    postStart = ''
      chmod 660 ${socket}
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
}
