{
  id = "system";
  text = "System";
  children = [
    {
      id = "screensaver";
      text = "Screensaver";
      action = "nixconf-screensaver force";
    }
    {
      id = "lock";
      text = "Lock";
      action = "hyprlock";
    }
    {
      id = "suspend";
      text = "Suspend";
      keywords = ["sleep"];
      action = "systemctl suspend";
    }
    {
      id = "hibernate";
      text = "Hibernate";
      condition = "nixconf-system available hibernate";
      action = "systemctl hibernate";
    }
    {
      id = "logout";
      text = "Logout";
      keywords = ["sign out"];
      action = "uwsm stop";
    }
    {
      id = "restart";
      text = "Restart";
      keywords = ["reboot"];
      action = "systemctl reboot";
    }
    {
      id = "shutdown";
      text = "Shutdown";
      keywords = ["power off"];
      action = "systemctl poweroff";
    }
    {
      id = "system-monitor";
      text = "System Monitor";
      keywords = ["btop" "processes" "resources"];
      action = "uwsm app -- kitty --class TUI.float --title 'System Monitor' btop";
    }
    {
      id = "nix";
      text = "Nix";
      keywords = ["nixos" "nh"];
      children = [
        {
          id = "build";
          text = "Build";
          action = "nixconf-system nix build";
        }
        {
          id = "test";
          text = "Test";
          action = "nixconf-system nix test";
        }
        {
          id = "switch";
          text = "Switch";
          action = "nixconf-system nix switch";
        }
        {
          id = "boot";
          text = "Boot";
          action = "nixconf-system nix boot";
        }
        {
          id = "update";
          text = "Update";
          action = "nixconf-system nix update";
        }
        {
          id = "clean";
          text = "Clean";
          keywords = ["garbage collect"];
          action = "nixconf-system nix clean";
        }
      ];
    }
  ];
}
