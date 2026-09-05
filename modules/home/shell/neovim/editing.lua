for key, action in pairs({
  y = "Yank",
  p = "PutAfter",
  P = "PutBefore",
  gp = "GPutAfter",
  gP = "GPutBefore",
  ["[y"] = "CycleForward",
  ["]y"] = "CycleBackward",
  ["]p"] = "PutIndentAfterLinewise",
  ["[p"] = "PutIndentBeforeLinewise",
  ["]P"] = "PutIndentAfterLinewise",
  ["[P"] = "PutIndentBeforeLinewise",
  [">p"] = "PutIndentAfterShiftRight",
  ["<p"] = "PutIndentAfterShiftLeft",
  [">P"] = "PutIndentBeforeShiftRight",
  ["<P"] = "PutIndentBeforeShiftLeft",
  ["=p"] = "PutAfterFilter",
  ["=P"] = "PutBeforeFilter",
}) do
  local visual = key == "y" or key == "p" or key == "P" or key == "gp" or key == "gP"
  vim.keymap.set(visual and { "n", "x" } or "n", key, "<Plug>(Yanky" .. action .. ")", { desc = action, silent = true })
end
for key, increment in pairs({ ["<C-a>"] = true, ["<C-x>"] = false, ["g<C-a>"] = true, ["g<C-x>"] = false }) do
  vim.keymap.set({ "n", "x" }, key, function()
    local mode = vim.fn.mode(true)
    local visual = mode == "v" or mode == "V" or mode == "\22"
    local method = (increment and "inc" or "dec")
      .. (key:sub(1, 1) == "g" and "_g" or "_")
      .. (visual and "visual" or "normal")
    return require("dial.map")[method](vim.g.dials_by_ft[vim.bo.filetype] or "default")
  end, { expr = true, desc = increment and "Increment" or "Decrement" })
end
vim.keymap.set({ "n", "o", "x" }, "<C-space>", function()
  require("flash").treesitter({ actions = { ["<C-space>"] = "next", ["<BS>"] = "prev" } })
end, { desc = "Treesitter Incremental Selection" })
vim.keymap.set("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next Todo Comment" })
vim.keymap.set("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous Todo Comment" })

-- LazyVim adds these guards around mini.pairs; the plugin alone does not.
local pairs_plugin = require("mini.pairs")
local open_pair = pairs_plugin.open
pairs_plugin.open = function(pair, pattern)
  if vim.fn.getcmdline() ~= "" then
    return open_pair(pair, pattern)
  end
  local opening, closing = pair:sub(1, 1), pair:sub(2, 2)
  local line, cursor = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)
  local next_char, before = line:sub(cursor[2] + 1, cursor[2] + 1), line:sub(1, cursor[2])
  if opening == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
    return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
  end
  if next_char:match([=[[%w%%%'%[%"%.%`%$]]=]) then
    return opening
  end
  local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
  for _, capture in ipairs(ok and captures or {}) do
    if capture.capture == "string" then
      return opening
    end
  end
  if next_char == closing and closing ~= opening then
    local _, opens = line:gsub(vim.pesc(opening), "")
    local _, closes = line:gsub(vim.pesc(closing), "")
    if closes > opens then
      return opening
    end
  end
  return open_pair(pair, pattern)
end
