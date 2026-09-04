let
  appendEntries = fields: ''
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
in {
  searchFunction = ''
    local function addBackgrounds(entries)
      ${appendEntries ''
      Text = "Appearance › Background › " .. label,
      Subtext = "Appearance › Background",
    ''}
    end
  '';

  menu = ''
    Name = "nixconf-background"
    NamePretty = "Background"
    Parent = "nixconf-appearance"
    Cache = false
    HideFromProviderlist = true
    FixedOrder = true

    function GetEntries()
      local entries = {}
      ${appendEntries ''
      Text = label,
    ''}
      return entries
    end
  '';
}
