-- Interaction contract from the Mac reference; no LazyVim runtime dependency.
local function map(mode, lhs, rhs, desc, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { silent = true, desc = desc }, opts or {}))
end

vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
for _, key in ipairs({ "j", "<Down>", "k", "<Up>" }) do
  local down = key == "j" or key == "<Down>"
  map(
    { "n", "x" },
    key,
    down and "v:count == 0 ? 'gj' : 'j'" or "v:count == 0 ? 'gk' : 'k'",
    down and "Down" or "Up",
    { expr = true }
  )
end
for key, direction in pairs({ h = "Left", j = "Lower", k = "Upper", l = "Right" }) do
  map("n", "<C-" .. key .. ">", "<C-w>" .. key, "Go to " .. direction .. " Window", { remap = true })
end
for key, command in pairs({
  Up = "resize +2",
  Down = "resize -2",
  Left = "vertical resize -2",
  Right = "vertical resize +2",
}) do
  map("n", "<C-" .. key .. ">", "<cmd>" .. command .. "<cr>", "Resize Window")
end
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", "Move Down")
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", "Move Up")
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", "Move Down")
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", "Move Up")
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", "Move Down")
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", "Move Up")
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", "Save File")
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd.nohlsearch()
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  return "<esc>"
end, "Escape and Clear hlsearch", { expr = true })
for _, key in ipairs({ ",", ".", ";" }) do
  map("i", key, key .. "<C-g>u")
end
map("x", "<", "<gv")
map("x", ">", ">gv")
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", "Add Comment Below")
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", "Add Comment Above")
for _, mode in ipairs({ "n", "x", "o" }) do
  map(mode, "n", "'Nn'[v:searchforward]" .. (mode == "n" and ".'zv'" or ""), "Next Search Result", { expr = true })
  map(mode, "N", "'nN'[v:searchforward]" .. (mode == "n" and ".'zv'" or ""), "Prev Search Result", { expr = true })
end
for lhs, command in pairs({
  ["<leader>fn"] = "enew",
  ["<leader>qq"] = "qa",
  ["<leader>K"] = "norm! K",
  ["<leader>bb"] = "e #",
  ["<leader>`"] = "e #",
  ["<leader>bD"] = "bd",
  ["<leader><tab>l"] = "tablast",
  ["<leader><tab>o"] = "tabonly",
  ["<leader><tab>f"] = "tabfirst",
  ["<leader><tab><tab>"] = "tabnew",
  ["<leader><tab>]"] = "tabnext",
  ["<leader><tab>d"] = "tabclose",
  ["<leader><tab>["] = "tabprevious",
}) do
  map("n", lhs, "<cmd>" .. command .. "<cr>", command)
end
map("n", "<leader>-", "<C-w>s", "Split Window Below", { remap = true })
map("n", "<leader>|", "<C-w>v", "Split Window Right", { remap = true })
map("n", "<leader>wd", "<C-w>c", "Delete Window", { remap = true })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, "Delete Buffer")
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, "Delete Other Buffers")
map("n", "<leader>bi", function()
  Snacks.bufdelete.invisible()
end, "Delete Invisible Buffers")
for lhs, item in pairs({
  H = { "CyclePrev", "Prev Buffer" },
  L = { "CycleNext", "Next Buffer" },
  ["[b"] = { "CyclePrev", "Prev Buffer" },
  ["]b"] = { "CycleNext", "Next Buffer" },
  ["[B"] = { "MovePrev", "Move buffer prev" },
  ["]B"] = { "MoveNext", "Move buffer next" },
  ["<leader>bp"] = { "TogglePin", "Toggle Pin" },
  ["<leader>bP"] = { "GroupClose ungrouped", "Delete Non-Pinned Buffers" },
  ["<leader>br"] = { "CloseRight", "Delete Buffers to the Right" },
  ["<leader>bl"] = { "CloseLeft", "Delete Buffers to the Left" },
  ["<leader>bj"] = { "Pick", "Pick Buffer" },
}) do
  map("n", lhs, "<cmd>BufferLine" .. item[1] .. "<cr>", item[2])
end
map("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, "Buffer Keymaps (which-key)")
map("n", "<C-w><space>", function()
  require("which-key").show({ keys = "<C-w>", loop = true })
end, "Window Hydra Mode (which-key)")
map("n", "<leader>ur", "<cmd>nohlsearch|diffupdate|normal! <C-L><cr>", "Redraw / Clear hlsearch / Diff Update")
map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")
for key, severity in pairs({ d = false, e = "ERROR", w = "WARN" }) do
  for bracket, count in pairs({ ["["] = -1, ["]"] = 1 }) do
    map("n", bracket .. key, function()
      vim.diagnostic.jump({
        count = count * vim.v.count1,
        severity = severity and vim.diagnostic.severity[severity] or nil,
        float = true,
      })
    end, (count == 1 and "Next " or "Prev ") .. (severity or "Diagnostic"))
  end
end
map({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ lsp_format = "fallback" })
end, "Format")
for key, local_buffer in pairs({ uf = false, uF = true }) do
  Snacks.toggle({
    name = local_buffer and "Auto Format (Buffer)" or "Auto Format (Global)",
    get = function()
      return local_buffer and vim.b.autoformat ~= false or (not local_buffer and vim.g.autoformat ~= false)
    end,
    set = function(value)
      if local_buffer then
        vim.b.autoformat = value
      else
        vim.g.autoformat = value
      end
    end,
  }):map("<leader>" .. key)
end
for key, option in pairs({ us = "spell", uw = "wrap", uL = "relativenumber" }) do
  Snacks.toggle.option(option):map("<leader>" .. key)
end
for key, toggle in pairs({
  ud = "diagnostics",
  ul = "line_number",
  uT = "treesitter",
  uD = "dim",
  ua = "animate",
  ug = "indent",
  uS = "scroll",
  uh = "inlay_hints",
  uz = "zen",
  wm = "zoom",
  uZ = "zoom",
  dpp = "profiler",
  dph = "profiler_highlights",
}) do
  Snacks.toggle[toggle]():map("<leader>" .. key)
end
Snacks.toggle.option("conceallevel", { off = 0, on = 2, name = "Conceal Level" }):map("<leader>uc")
Snacks.toggle.option("showtabline", { off = 0, on = 2, name = "Tabline" }):map("<leader>uA")
Snacks.toggle({
  name = "Mini Pairs",
  get = function()
    return not vim.g.minipairs_disable
  end,
  set = function(value)
    vim.g.minipairs_disable = not value
  end,
}):map("<leader>up")
Snacks.toggle({
  name = "Git Signs",
  get = function()
    return require("gitsigns.config").config.signcolumn
  end,
  set = function(value)
    require("gitsigns").toggle_signs(value)
  end,
}):map("<leader>uG")
map("n", "<leader>ui", vim.show_pos, "Inspect Pos")
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, "Inspect Tree")

local group = vim.api.nvim_create_augroup("nixconf_editor", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.cmd.checktime()
    end
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = {
    "help",
    "qf",
    "checkhealth",
    "startuptime",
    "gitsigns-blame",
    "grug-far",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "dap-float",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    map("n", "q", function()
      vim.cmd.close()
      pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
    end, "Quit buffer", { buffer = event.buf })
  end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(event)
    if vim.bo[event.buf].filetype == "gitcommit" then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(event)
    if not event.match:match("^%w%w+:[\\/][\\/]") then
      vim.fn.mkdir(vim.fn.fnamemodify(vim.uv.fs_realpath(event.match) or event.match, ":p:h"), "p")
    end
  end,
})
