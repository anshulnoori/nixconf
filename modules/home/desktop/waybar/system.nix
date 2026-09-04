_: {
  flake.modules.homeManager.desktop.programs.waybar.settings.mainBar = let
    floatingTerminal = command: "kitty --class TUI.float ${command}";
  in {
    cpu = {
      interval = 5;
      format = "󰍛";
      tooltip-format = "System monitor\nLeft: btop\nMiddle: journal\nRight: GPU";
      on-click = floatingTerminal "btop";
      on-click-middle = floatingTerminal "lazyjournal";
      on-click-right = floatingTerminal "nvtop";
    };
    network = {
      format = "{icon}";
      format-wifi = "{icon}";
      format-ethernet = "󰀂";
      format-disconnected = "󰤮";
      format-icons = [
        "󰤯"
        "󰤟"
        "󰤢"
        "󰤥"
        "󰤨"
      ];
      tooltip-format-wifi = "{essid} ({frequency} GHz)";
      tooltip-format-ethernet = "Connected";
      tooltip-format-disconnected = "Disconnected";
      interval = 3;
      on-click = floatingTerminal "impala";
    };
    bluetooth = {
      format = "";
      format-off = "󰂲";
      format-disabled = "󰂲";
      format-connected = "󰂱";
      format-no-controller = "󰂲";
      tooltip-format = "Devices connected: {num_connections}";
      on-click = floatingTerminal "bluetui";
    };
    pulseaudio = {
      format = "{icon}";
      format-muted = "";
      format-icons = {
        headphone = "";
        headset = "";
        default = [
          ""
          ""
          ""
        ];
      };
      tooltip-format = "Playing at {volume}%";
      scroll-step = 5;
      on-click = floatingTerminal "wiremix";
      on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    };
  };
}
