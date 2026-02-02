{
  flake.nixosModules.thelessnas-backups = {
    services.borgbackup.repos = {
      postgres = {
        path = "/moon/borgbackup/postgres";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBTF3kpnHtw/4kr1/bLcIer3+WDnO9TQnAIskg0paP0q"
        ];
      };

      hass = {
        path = "/moon/borgbackup/hass";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBm2A8lsONm20BXepVyA/Aot6SwqZ4cuwX+tPQQgPmde"
        ];
      };

      thelessone = {
        user = "thelessone-borg";
        group = "thelessone-borg";
        path = "/moon/borgbackup/thelessone";
        allowSubRepos = true;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHWrN8P3hhKBSKi0GBqXTMWIT34H9Iqf2sXaSuiYmkPi"
        ];
      };
    };
  };
}
