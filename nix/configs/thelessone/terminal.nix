{
  flake.homeModules.terminal = {
    programs.alacritty.settings.terminal.shell = {
      program = "zellij";
      args = [
        "-l"
        "welcome"
      ];
    };
  };
}
