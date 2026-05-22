{
  flake.nixosModules.thelessone-arr =
    { lib, config, ... }:

    let
      inherit (lib) mkOption types;

      cfg = config.thelessone.arr;
    in

    {
      options.thelessone.arr = {
        home = mkOption {
          type = types.path;
          default = "/mnt/raid/arr-stack";
          readOnly = true;
        };

        group = mkOption {
          type = types.str;
          default = "arr";
        };
      };

      config.users = lib.mkIf (cfg.group == "arr") {
        groups.arr = { };
        users.${config.self.mainUser}.extraGroups = [ cfg.group ];
      };
    };
}
