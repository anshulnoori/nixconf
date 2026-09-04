{
  id = "trigger";
  text = "Trigger";
  children = [
    {
      id = "reminder";
      text = "Reminder";
      children = [
        {
          id = "add";
          text = "Add reminder";
          keywords = ["todo" "task" "quick add"];
          action = "nixconf-reminder add";
        }
        {
          id = "upcoming";
          text = "Upcoming";
          keywords = ["todo" "tasks"];
          action = "nixconf-reminder upcoming";
        }
        {
          id = "todoist";
          text = "Todoist";
          keywords = ["todo" "tasks"];
          action = "nixconf-reminder open";
        }
      ];
    }
    {
      id = "capture";
      text = "Capture";
      children = [
        {
          id = "screenshot";
          text = "Screenshot";
          children = [
            {
              id = "region";
              text = "Region";
              action = "capture-screenshot region";
            }
            {
              id = "fullscreen";
              text = "Full Screen";
              keywords = ["monitor"];
              action = "capture-screenshot fullscreen";
            }
          ];
        }
        {
          id = "stop-screenrecording";
          text = "Stop Screen Recording";
          keywords = ["video" "recording"];
          condition = "capture-screenrecord active";
          action = "capture-screenrecord stop";
        }
        {
          id = "screenrecording";
          text = "Screen Recording";
          keywords = ["video" "record"];
          condition = "capture-screenrecord inactive";
          children = [
            {
              id = "no-audio";
              text = "No Audio";
              action = "capture-screenrecord no-audio";
            }
            {
              id = "desktop-audio";
              text = "Desktop Audio";
              action = "capture-screenrecord desktop-audio";
            }
            {
              id = "microphone";
              text = "Desktop and Microphone";
              keywords = ["mic"];
              action = "capture-screenrecord microphone";
            }
            {
              id = "webcam";
              text = "Desktop, Microphone, and Webcam";
              keywords = ["camera"];
              action = "capture-screenrecord webcam";
            }
          ];
        }
        {
          id = "text";
          text = "Text";
          keywords = ["ocr" "extract"];
          action = "capture-text";
        }
        {
          id = "qr-code";
          text = "QR Code";
          keywords = ["decode"];
          action = "capture-qr";
        }
        {
          id = "color";
          text = "Color";
          keywords = ["picker"];
          action = "capture-color";
        }
      ];
    }
    {
      id = "share";
      text = "Share";
      children = [
        {
          id = "clipboard";
          text = "Clipboard";
          action = "nixconf-share clipboard";
        }
        {
          id = "file";
          text = "File";
          action = "nixconf-share file";
        }
        {
          id = "folder";
          text = "Folder";
          keywords = ["directory"];
          action = "nixconf-share folder";
        }
        {
          id = "receive";
          text = "Receive";
          keywords = ["localsend"];
          action = "nixconf-share receive";
        }
        {
          id = "qr-code";
          text = "QR Code";
          keywords = ["clipboard"];
          action = "nixconf-share qr";
        }
      ];
    }
    {
      id = "toggle";
      text = "Toggle";
      children = [
        {
          id = "screensaver";
          text = "Screensaver";
          action = "nixconf-screensaver toggle";
        }
        {
          id = "nightlight";
          text = "Nightlight";
          keywords = ["night light" "blue light"];
          action = "nixconf-toggle nightlight";
        }
        {
          id = "caffeine";
          text = "Caffeine";
          keywords = ["caffeinate" "decaffeinate" "awake" "idle"];
          action = "nixconf-toggle caffeine";
        }
        {
          id = "notifications";
          text = "Notifications";
          keywords = ["do not disturb" "dnd" "silence"];
          action = "nixconf-toggle notifications";
        }
        {
          id = "bar";
          text = "Bar";
          keywords = ["waybar"];
          action = "nixconf-toggle bar";
        }
        {
          id = "monitor-scaling";
          text = "Monitor Scaling";
          keywords = ["display" "scale"];
          action = "nixconf-edit monitor-scaling";
        }
      ];
    }
    {
      id = "hardware";
      text = "Hardware";
      children = [
        {
          id = "laptop-display";
          text = "Laptop Display";
          condition = "nixconf-hardware available laptop-display";
          action = "nixconf-hardware laptop-display";
        }
        {
          id = "mirror-display";
          text = "Mirror Display";
          condition = "nixconf-hardware available mirror-display";
          action = "nixconf-hardware mirror-display";
        }
        {
          id = "hybrid-gpu";
          text = "Hybrid GPU";
          condition = "nixconf-hardware available hybrid-gpu";
          action = "nixconf-edit graphics";
        }
        {
          id = "touchpad";
          text = "Touchpad";
          condition = "nixconf-hardware available touchpad";
          action = "nixconf-hardware touchpad";
        }
        {
          id = "touchpad-haptics";
          text = "Touchpad Haptics";
          condition = "nixconf-hardware available touchpad-haptics";
          children = [
            {
              id = "low";
              text = "Low";
              action = "nixconf-hardware touchpad-haptics low";
            }
            {
              id = "mid";
              text = "Mid";
              keywords = ["medium"];
              action = "nixconf-hardware touchpad-haptics mid";
            }
            {
              id = "high";
              text = "High";
              action = "nixconf-hardware touchpad-haptics high";
            }
          ];
        }
        {
          id = "touchscreen";
          text = "Touchscreen";
          condition = "nixconf-hardware available touchscreen";
          action = "nixconf-hardware touchscreen";
        }
      ];
    }
  ];
}
