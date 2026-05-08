{
  flake.nixosModules.thelessone-services =
    _:

    {
      systemd.targets.server-services = {
        description = "All non-essential server services";
        after = [
          "multi-user.target"
          "mnt-raid.automount"
          "network-online.target"
        ];
        wants = [
          "network-online.target"
          "mnt-raid.automount"
        ];
        wantedBy = [ "multi-user.target" ];
      };
    };
}
