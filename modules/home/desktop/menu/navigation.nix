_: {
  flake.modules.homeManager.desktop = {
    lib,
    pkgs,
    ...
  }: let
    tree = [
      {
        id = "apps";
        text = "Apps";
        keywords = ["applications" "launcher"];
        action = "walker";
      }
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
      {
        id = "appearance";
        text = "Appearance";
        children = [
          {
            id = "background";
            text = "Background";
            keywords = ["wallpaper"];
            submenu = "nixconf-background";
          }
          {
            id = "stylix";
            text = "Stylix";
            keywords = ["theme" "colors"];
            action = "nixconf-edit stylix";
          }
          {
            id = "font";
            text = "Font";
            keywords = ["typeface"];
            action = "nixconf-edit font";
          }
          {
            id = "hyprland";
            text = "Hyprland";
            keywords = ["compositor" "window manager"];
            action = "nixconf-edit hyprland";
          }
          {
            id = "waybar";
            text = "Waybar";
            keywords = ["bar"];
            action = "nixconf-edit waybar";
          }
          {
            id = "lock-screen";
            text = "Lock Screen";
            keywords = ["hyprlock"];
            action = "nixconf-edit lock-screen";
          }
          {
            id = "screensaver";
            text = "Screensaver";
            action = "nixconf-edit screensaver";
          }
        ];
      }
      {
        id = "setup";
        text = "Setup";
        children = [
          {
            id = "audio";
            text = "Audio";
            keywords = ["pipewire" "wireplumber"];
            action = "nixconf-edit audio";
          }
          {
            id = "wifi";
            text = "Wi-Fi";
            keywords = ["wireless" "iwd"];
            action = "nixconf-edit wifi";
          }
          {
            id = "bluetooth";
            text = "Bluetooth";
            keywords = ["bluez"];
            action = "nixconf-edit bluetooth";
          }
          {
            id = "power-profile";
            text = "Power Profile";
            keywords = ["performance" "governor"];
            action = "nixconf-edit power-profile";
          }
          {
            id = "system-sleep";
            text = "System Sleep";
            keywords = ["suspend" "hibernate" "idle"];
            action = "nixconf-edit system-sleep";
          }
          {
            id = "displays";
            text = "Displays";
            keywords = ["monitors"];
            action = "nixconf-edit displays";
          }
          {
            id = "keybindings";
            text = "Keybindings";
            keywords = ["shortcuts"];
            action = "nixconf-edit keybindings";
          }
          {
            id = "input";
            text = "Input";
            keywords = ["keyboard" "mouse"];
            action = "nixconf-edit input";
          }
          {
            id = "dns";
            text = "DNS";
            keywords = ["cloudflare" "resolved"];
            action = "nixconf-edit dns";
          }
          {
            id = "security";
            text = "Security";
            keywords = ["sudo" "fido2" "fingerprint"];
            action = "nixconf-edit security";
          }
          {
            id = "config";
            text = "Config";
            keywords = ["nixos" "configuration"];
            action = "nixconf-edit config";
          }
        ];
      }
      {
        id = "packages";
        text = "Packages";
        children = [
          {
            id = "install";
            text = "Install";
            keywords = ["nixpkgs" "add"];
            action = "present-terminal 'Install package' nixpkgs-package-search install";
          }
          {
            id = "remove";
            text = "Remove";
            keywords = ["uninstall"];
            action = "present-terminal 'Remove package' nixpkgs-package-search remove";
          }
        ];
      }
      {
        id = "about";
        text = "About";
        keywords = ["system information" "fastfetch"];
        action = "present-terminal About fastfetch";
      }
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
    ];

    quote = builtins.toJSON;
    luaList = values: "{ ${lib.concatStringsSep ", " (map quote values)} }";
    menuName = path:
      if path == []
      then "nixconf"
      else "nixconf-${lib.concatStringsSep "-" path}";
    combineCondition = inherited: own:
      if inherited == null
      then own
      else if own == null
      then inherited
      else "${inherited} && ${own}";
    nodeSubmenu = path: node:
      if node ? children
      then menuName path
      else node.submenu or null;
    renderEntry = {
      node,
      path,
      global ? false,
      condition ? node.condition or null,
    }: let
      breadcrumb = lib.concatStringsSep " › " (map (part: part.text) path);
      submenu = nodeSubmenu (map (part: part.id) path) node;
      fields =
        [
          "Text = ${quote (
            if global
            then breadcrumb
            else node.text
          )}"
        ]
        ++ lib.optional global "Subtext = ${quote breadcrumb}"
        ++ lib.optional (node ? keywords) "Keywords = ${luaList node.keywords}"
        ++ lib.optional (submenu != null) "SubMenu = ${quote submenu}"
        ++ lib.optional (node ? action) "Actions = { select = ${quote node.action} }"
        ++ lib.optional (condition != null) "Condition = ${quote condition}";
    in "{ ${lib.concatStringsSep ", " fields} }";
    visibleFunction = ''
      local function available(command)
        if command == nil then
          return true
        end

        local result = os.execute(command .. " >/dev/null 2>&1")
        return result == true or result == 0
      end

      local function visible(entries)
        local result = {}
        for _, entry in ipairs(entries) do
          if available(entry.Condition) then
            table.insert(result, entry)
          end
        end
        return result
      end
    '';
    renderMenu = menu: ''
      Name = ${quote (menuName menu.path)}
      NamePretty = ${quote menu.text}
      Parent = ${quote menu.parent}
      Cache = false
      HideFromProviderlist = true
      FixedOrder = true

      ${visibleFunction}

      local entries = {
        ${lib.concatStringsSep ",\n  " (map (node:
        renderEntry {
          inherit node;
          path = menu.pathParts ++ [node];
        })
      menu.children)}
      }

      function GetEntries()
        return visible(entries)
      end
    '';
    collectMenus = parentPath: parentParts: nodes:
      lib.concatMap (
        node:
          lib.optionals (node ? children) (
            let
              path = parentPath ++ [node.id];
              parts = parentParts ++ [node];
            in
              [
                {
                  inherit path;
                  inherit (node) children text;
                  pathParts = parts;
                  parent = menuName parentPath;
                }
              ]
              ++ collectMenus path parts node.children
          )
      )
      nodes;
    flattenNodes = inherited: parts: nodes:
      lib.concatMap (
        node: let
          condition = combineCondition inherited (node.condition or null);
          path = parts ++ [node];
        in
          [
            {
              inherit condition node path;
            }
          ]
          ++ lib.optionals (node ? children) (flattenNodes condition path node.children)
      )
      nodes;
    menuFiles = lib.listToAttrs (
      map (menu: {
        name = "elephant/menus/${menuName menu.path}.lua";
        value.text = renderMenu menu;
      }) (collectMenus [] [] tree)
    );
    rootEntries = map (node:
      renderEntry {
        inherit node;
        path = [node];
      })
    tree;
    searchEntries = map (entry:
      renderEntry {
        inherit (entry) node path condition;
        global = true;
      }) (flattenNodes null [] tree);
    rootMenu = ''
      Name = "nixconf"
      NamePretty = "Desktop"
      Cache = false
      HideFromProviderlist = true
      FixedOrder = true

      ${visibleFunction}

      local roots = {
        ${lib.concatStringsSep ",\n  " rootEntries}
      }

      local searchable = {
        ${lib.concatStringsSep ",\n  " searchEntries}
      }

      local function addBackgrounds(entries)
        local handle = io.popen("nixconf-wallpaper list 2>/dev/null")
        if handle then
          for line in handle:lines() do
            local path, label = line:match("^([^\t]+)\t(.+)$")
            if path and label then
              table.insert(entries, {
                Text = "Appearance › Background › " .. label,
                Subtext = "Appearance › Background",
                Value = path,
                Preview = path,
                PreviewType = "file",
                Actions = { select = "nixconf-wallpaper set" },
              })
            end
          end
          handle:close()
        end
      end

      function GetEntries(query)
        if query == nil or query == "" then
          return visible(roots)
        end

        local entries = visible(searchable)
        addBackgrounds(entries)
        return entries
      end
    '';
    backgroundMenu = ''
      Name = "nixconf-background"
      NamePretty = "Background"
      Parent = "nixconf-appearance"
      Cache = false
      HideFromProviderlist = true
      FixedOrder = true

      function GetEntries()
        local entries = {}
        local handle = io.popen("nixconf-wallpaper list 2>/dev/null")
        if handle then
          for line in handle:lines() do
            local path, label = line:match("^([^\t]+)\t(.+)$")
            if path and label then
              table.insert(entries, {
                Text = label,
                Value = path,
                Preview = path,
                PreviewType = "file",
                Actions = { select = "nixconf-wallpaper set" },
              })
            end
          end
          handle:close()
        end
        return entries
      end
    '';
    launcher = pkgs.writeShellApplication {
      name = "nixconf-menu";
      runtimeInputs = [pkgs.walker];
      text = ''
        exec walker \
          --width 644 \
          --minheight 300 \
          --maxheight 300 \
          --placeholder "Search actions…" \
          --provider menus:nixconf
      '';
    };
  in {
    home.packages = [launcher];

    xdg.configFile =
      menuFiles
      // {
        "elephant/menus/nixconf.lua".text = rootMenu;
        "elephant/menus/nixconf-background.lua".text = backgroundMenu;
      };
  };
}
