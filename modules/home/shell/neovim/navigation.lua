local function map(lhs, rhs, desc, mode)
  vim.keymap.set(mode or "n", lhs, rhs, { silent = true, desc = desc })
end

local root = require("nixconf.root")

for lhs, item in pairs({
  [","] = { "buffers", "Buffers" },
  [":"] = { "command_history", "Command History" },
  n = { "notifications", "Notification History" },
  fb = { "buffers", "Buffers" },
  fg = { "git_files", "Find Files (git-files)" },
  fp = { "projects", "Projects" },
  gd = { "git_diff", "Git Diff (hunks)" },
  gs = { "git_status", "Git Status" },
  gS = { "git_stash", "Git Stash" },
  gL = { "git_log", "Git Log (cwd)" },
  gb = { "git_log_line", "Git Blame Line" },
  gf = { "git_log_file", "Git Current File History" },
  sb = { "lines", "Buffer Lines" },
  sB = { "grep_buffers", "Grep Open Buffers" },
  ['s"'] = { "registers", "Registers" },
  ["s/"] = { "search_history", "Search History" },
  sa = { "autocmds", "Autocmds" },
  sc = { "command_history", "Command History" },
  sC = { "commands", "Commands" },
  sd = { "diagnostics", "Diagnostics" },
  sD = { "diagnostics_buffer", "Buffer Diagnostics" },
  sh = { "help", "Help Pages" },
  sH = { "highlights", "Highlights" },
  si = { "icons", "Icons" },
  sj = { "jumps", "Jumps" },
  sk = { "keymaps", "Keymaps" },
  sl = { "loclist", "Location List" },
  sM = { "man", "Man Pages" },
  sm = { "marks", "Marks" },
  sR = { "resume", "Resume" },
  sq = { "qflist", "Quickfix List" },
  su = { "undo", "Undotree" },
  uC = { "colorschemes", "Colorschemes" },
  st = { "todo_comments", "Todo" },
}) do
  map("<leader>" .. lhs, function()
    Snacks.picker[item[1]]()
  end, item[2])
end
for lhs, source in pairs({
  ["<space>"] = "files",
  ff = "files",
  ["/"] = "grep",
  sg = "grep",
  sw = "grep_word",
  fr = "recent",
}) do
  map("<leader>" .. lhs, function()
    Snacks.picker[source]({ cwd = root() })
  end, source .. " (Root Dir)", source == "grep_word" and { "n", "x" } or "n")
end
for lhs, source in pairs({ fF = "files", sG = "grep", sW = "grep_word" }) do
  map("<leader>" .. lhs, function()
    Snacks.picker[source]()
  end, source .. " (cwd)", source == "grep_word" and { "n", "x" } or "n")
end
map("<leader>fR", function()
  Snacks.picker.recent({ filter = { cwd = true } })
end, "Recent (cwd)")
map("<leader>gD", function()
  Snacks.picker.git_diff({ base = "origin", group = true })
end, "Git Diff (origin)")
for lhs, source in pairs({ gi = "gh_issue", gp = "gh_pr", gI = "gh_issue", gP = "gh_pr" }) do
  local all = lhs:sub(2):match("%u") ~= nil
  map("<leader>" .. lhs, function()
    Snacks.picker[source](all and { state = "all" } or {})
  end, source .. (all and " (all)" or " (open)"))
end
map("<leader>fB", function()
  Snacks.picker.buffers({ hidden = true, nofile = true })
end, "Buffers (all)")
map("<leader>fc", function()
  Snacks.picker.files({ cwd = "/etc/nixos" })
end, "Find Config File")
map("<leader>sT", function()
  Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
end, "Todo/Fix/Fixme")
map("<leader>xt", "<cmd>Trouble todo toggle<cr>", "Todo (Trouble)")
map("<leader>xT", "<cmd>Trouble todo toggle filter={tag={TODO,FIX,FIXME}}<cr>", "Todo/Fix/Fixme (Trouble)")
map("<leader>p", function()
  Snacks.picker.yanky()
end, "Open Yank History", { "n", "x" })
map("<leader>e", function()
  Snacks.explorer({ cwd = root() })
end, "Explorer Snacks (root dir)")
map("<leader>E", function()
  Snacks.explorer()
end, "Explorer Snacks (cwd)")
map("<leader>fe", function()
  Snacks.explorer({ cwd = root() })
end, "Explorer Snacks (root dir)")
map("<leader>fE", function()
  Snacks.explorer()
end, "Explorer Snacks (cwd)")
map("<leader>gg", function()
  Snacks.lazygit({ cwd = vim.fs.root(root(), ".git") or root() })
end, "Lazygit (Root Dir)")
map("<leader>gG", function()
  Snacks.lazygit()
end, "Lazygit (cwd)")
map("<leader>gl", function()
  Snacks.picker.git_log({ cwd = vim.fs.root(root(), ".git") or root() })
end, "Git Log")
map("<leader>gB", function()
  Snacks.gitbrowse()
end, "Git Browse (open)", { "n", "x" })
map("<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, "Git Browse (copy)", { "n", "x" })
map("<leader>ft", function()
  Snacks.terminal(nil, { cwd = root() })
end, "Terminal (Root Dir)")
map("<leader>fT", function()
  Snacks.terminal()
end, "Terminal (cwd)")
map("<C-/>", function()
  Snacks.terminal.toggle(nil, { cwd = root() })
end, "Terminal (Root Dir)", { "n", "t" })
map("<C-_>", function()
  Snacks.terminal.toggle(nil, { cwd = root() })
end, "which_key_ignore", { "n", "t" })
map("<leader>.", function()
  Snacks.scratch()
end, "Toggle Scratch Buffer")
map("<leader>S", function()
  Snacks.scratch.select()
end, "Select Scratch Buffer")
map("<leader>un", function()
  Snacks.notifier.hide()
end, "Dismiss All Notifications")
map("<leader>sr", function()
  local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
  require("grug-far").open({ transient = true, prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil } })
end, "Search and Replace", { "n", "x" })
for lhs, method in pairs({ snl = "last", snh = "history", sna = "all", snd = "dismiss" }) do
  map("<leader>" .. lhs, function()
    require("noice").cmd(method)
  end, "Noice " .. method)
end
map("<S-Enter>", function()
  require("noice").redirect(vim.fn.getcmdline())
end, "Redirect Cmdline", "c")
for key, distance in pairs({ ["<C-f>"] = 4, ["<C-b>"] = -4 }) do
  vim.keymap.set({ "i", "n", "s" }, key, function()
    if not require("noice.lsp").scroll(distance) then
      return key
    end
  end, { silent = true, expr = true, desc = "Scroll " .. (distance > 0 and "Forward" or "Backward") })
end
for lhs, command in pairs({
  xx = "diagnostics",
  xX = "diagnostics filter.buf=0",
  cs = "symbols",
  cS = "lsp",
  xL = "loclist",
  xQ = "qflist",
}) do
  map("<leader>" .. lhs, "<cmd>Trouble " .. command .. " toggle<cr>", command .. " (Trouble)")
end
for lhs, command in pairs({ xl = "l", xq = "c" }) do
  map("<leader>" .. lhs, function()
    local win = command == "l" and vim.fn.getloclist(0, { winid = 0 }).winid or vim.fn.getqflist({ winid = 0 }).winid
    local ok, err = pcall(vim.cmd, command .. (win ~= 0 and "close" or "open"))
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end, command == "l" and "Location List" or "Quickfix List")
end
for key, direction in pairs({ ["[q"] = "prev", ["]q"] = "next" }) do
  map(key, function()
    if require("trouble").is_open() then
      require("trouble")[direction]({ skip_groups = true, jump = true })
    else
      local ok, err = pcall(vim.cmd, "c" .. direction)
      if not ok then
        vim.notify(err, vim.log.levels.ERROR)
      end
    end
  end, direction .. " Trouble/Quickfix Item")
end

-- Picker root/cwd toggle belongs to the active buffer, not its input buffer.
Snacks.config.picker = vim.tbl_deep_extend("force", Snacks.config.picker or {}, {
  actions = {
    toggle_cwd = function(p)
      local project = root(p.input.filter.current_buf)
      p:set_cwd(p:cwd() == project and vim.uv.cwd() or project)
      p:find()
    end,
    trouble_open = function(...)
      return require("trouble.sources.snacks").actions.trouble_open.action(...)
    end,
    flash = function(picker)
      require("flash").jump({
        pattern = "^",
        label = { after = { 0, 0 } },
        search = {
          mode = "search",
          exclude = {
            function(win)
              return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
            end,
          },
        },
        action = function(match)
          picker.list:_move(picker.list:row2idx(match.pos[1]), true, true)
        end,
      })
    end,
  },
  win = {
    input = {
      keys = {
        ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" } },
        ["<a-t>"] = { "trouble_open", mode = { "n", "i" } },
        ["<a-s>"] = { "flash", mode = { "n", "i" } },
        s = { "flash" },
      },
    },
  },
})
