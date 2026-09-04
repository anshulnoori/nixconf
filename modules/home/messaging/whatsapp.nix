_: {
  flake.modules.homeManager.desktop.xdg.desktopEntries.whatsapp = {
    name = "WhatsApp";
    genericName = "Messaging";
    exec = "brave-origin --app=https://web.whatsapp.com/";
    icon = "brave-origin";
    categories = ["Network" "InstantMessaging"];
    terminal = false;
  };
}
