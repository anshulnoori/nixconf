_: {
  flake.modules.homeManager.desktop.xdg.desktopEntries.desmos = {
    name = "Desmos";
    genericName = "Graphing Calculator";
    exec = "brave-origin --app=https://www.desmos.com/calculator";
    icon = "brave-origin";
    categories = ["Education"];
    terminal = false;
  };
}
