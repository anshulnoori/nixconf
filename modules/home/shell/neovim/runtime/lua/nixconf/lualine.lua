-- Adapted from LazyVim's lualine components (Apache-2.0; see LICENSE.LazyVim).
-- Keep presentation local; project flakes own LSP and debugger integrations.
local root = require("nixconf.root")
local M = {}

local function highlight(component, text, group)
  text = text:gsub("%%", "%%%%")
  component.hl_cache = component.hl_cache or {}
  if not component.hl_cache[group] then
    local extract = require("lualine.utils.utils").extract_highlight_colors
    local styles = {}
    for _, style in ipairs({ "bold", "italic" }) do
      if extract(group, style) then
        styles[#styles + 1] = style
      end
    end
    component.hl_cache[group] = component:create_hl({
      fg = extract(group, "fg"),
      gui = #styles > 0 and table.concat(styles, ",") or nil,
    }, "nixconf_" .. group)
  end
  return component:format_hl(component.hl_cache[group]) .. text .. component:get_default_hl()
end

M.root_dir = {
  function()
    return "󱉭  " .. vim.fs.basename(root()):gsub("%%", "%%%%")
  end,
  cond = function()
    return root() ~= vim.uv.fs_realpath(vim.uv.cwd())
  end,
  color = function()
    return { fg = require("snacks").util.color("Special") }
  end,
}

M.pretty_path = {
  function(self)
    local path = vim.fn.expand("%:p")
    if path == "" then
      return ""
    end
    local cwd, project = vim.uv.fs_realpath(vim.uv.cwd()), root()
    if vim.startswith(path, cwd .. "/") then
      path = path:sub(#cwd + 2)
    elseif vim.startswith(path, project .. "/") then
      path = path:sub(#project + 2)
    end
    local parts = vim.split(path, "/", { plain = true })
    if #parts > 3 then
      parts = { parts[1], "…", parts[#parts - 1], parts[#parts] }
    end
    local filename = table.remove(parts)
    local directory = #parts > 0 and table.concat(parts, "/") .. "/" or ""
    return directory:gsub("%%", "%%%%")
      .. highlight(self, filename, vim.bo.modified and "MatchParen" or "Bold")
      .. (vim.bo.readonly and highlight(self, " 󰌾 ", "MatchParen") or "")
  end,
}

local symbols
M.symbols = {
  function()
    return symbols.get()
  end,
  cond = function()
    if vim.b.trouble_lualine == false then
      return false
    end
    symbols = symbols
      or require("trouble").statusline({
        mode = "symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{kind_icon}{symbol.name:Normal}",
        hl_group = "lualine_c_normal",
      })
    return symbols.has()
  end,
}

return M
