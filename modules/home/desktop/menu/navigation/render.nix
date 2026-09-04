_: {
  flake.modules.homeManager.desktop = {
    lib,
    pkgs,
    ...
  }: let
    icons = import ./icons.data;
    tree = map import [
      ./entries/apps.data
      ./entries/trigger.data
      ./entries/appearance.data
      ./entries/setup.data
      ./entries/packages.data
      ./entries/about.data
      ./entries/system.data
    ];
    iconFor = node: node.icon or (icons.${node.id} or "󰇘");
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
      displayText = "${iconFor node}  ${
        if global
        then breadcrumb
        else node.text
      }";
      submenu = nodeSubmenu (map (part: part.id) path) node;
      fields =
        [
          "Text = ${quote displayText}"
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
    appendBackgrounds = fields: ''
      local handle = io.popen("nixconf-wallpaper list 2>/dev/null")
      if handle then
        for line in handle:lines() do
          local path, label = line:match("^([^\t]+)\t(.+)$")
          if path and label then
            table.insert(entries, {
              ${fields}
              Value = path,
              Preview = path,
              PreviewType = "file",
              Actions = { select = "nixconf-wallpaper set" },
            })
          end
        end
        handle:close()
      end
    '';
    backgroundSearchFunction = ''
      local function addBackgrounds(entries)
        ${appendBackgrounds ''
        Text = "Appearance › Background › " .. label,
        Subtext = "Appearance › Background",
      ''}
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
        ${appendBackgrounds ''
        Text = label,
      ''}
        return entries
      end
    '';
    menuFiles = lib.listToAttrs (
      map (menu: {
        name = "elephant/menus/${menuName menu.path}.lua";
        value.text = renderMenu menu;
      }) (collectMenus [] [] tree)
    );
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

      ${backgroundSearchFunction}

      function GetEntries(query)
        if query == nil or query == "" then
          return visible(roots)
        end

        local entries = visible(searchable)
        addBackgrounds(entries)
        return entries
      end
    '';
    launcher = pkgs.writeShellApplication {
      name = "nixconf-menu";
      runtimeInputs = [pkgs.walker];
      text = ''
        exec walker \
          --width 295 \
          --minheight 1 \
          --maxheight 630 \
          --placeholder "Go…" \
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
