{
  flake.nixosModules.thelessone-mailserver = {
    sec.no-reply-password = {
      mode = "0440";
      group = "no-reply";
    };

    users.groups.no-reply = { };
  };
}
