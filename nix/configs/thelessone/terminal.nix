{
  flake.homeModules.thelessone-terminal = {
    programs.alacritty.enable = true;
    programs.alacritty.settings.terminal.shell = {
      program = "zellij";
      args = [
        "-l"
        "welcome"
      ];
    };
  };
}
