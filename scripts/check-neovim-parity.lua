-- Run in an isolated nvf session:
-- nvim --headless -i NONE '+luafile scripts/check-neovim-parity.lua'
-- This checks the loaded configuration, not a second hand-written setup.
vim.defer_fn(function()
  local ok, err = xpcall(function()
    local function equal(actual, expected, label)
      assert(
        vim.deep_equal(actual, expected),
        label .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual)
      )
    end
    local function mapping(key, mode)
      local value = vim.fn.maparg(key, mode or "n", false, true)
      assert(next(value), "Missing " .. (mode or "n") .. " mapping: " .. key)
      return value
    end
    equal(vim.g.mapleader, " ", "leader")
    equal(vim.g.maplocalleader, "\\", "local leader")
    equal(vim.o.timeoutlen, 300, "effective mapping timeout (including nvf tm alias)")
    equal(vim.o.scrolloff, 4, "scroll context")
    equal(vim.o.laststatus, 3, "global statusline")
    equal(vim.o.pumheight, 10, "completion menu height")
    local components = require("nixconf.lualine")
    local directory = vim.fn.tempname()
    local cwd, buffer = vim.uv.cwd(), vim.api.nvim_get_current_buf()
    vim.fn.mkdir(directory .. "/project/.git", "p")
    vim.fn.mkdir(directory .. "/project/src/deep/nested", "p")
    local file = directory .. "/project/src/deep/nested/100%.txt"
    vim.fn.writefile({ "Public statusline fixture" }, file)
    local fixture = vim.api.nvim_create_buf(true, false)
    local checked, failure = xpcall(function()
      vim.api.nvim_set_current_buf(fixture)
      vim.api.nvim_buf_set_name(fixture, file)
      vim.api.nvim_set_current_dir(directory .. "/project")
      equal(components.root_dir.cond(), false, "hide redundant root badge")
      local self = {
        create_hl = function(_, _, name)
          return name
        end,
        format_hl = function(_, name)
          return "<" .. name .. ">"
        end,
        get_default_hl = function()
          return "</>"
        end,
      }
      equal(
        components.pretty_path[1](self),
        "src/…/nested/<nixconf_Bold>100%%.txt</>",
        "short path and escaped percent"
      )
      vim.bo.modified = true
      vim.bo.readonly = true
      equal(
        components.pretty_path[1](self),
        "src/…/nested/<nixconf_MatchParen>100%%.txt</><nixconf_MatchParen> 󰌾 </>",
        "modified filename and readonly lock"
      )
      vim.api.nvim_set_current_dir(directory)
      equal(components.root_dir.cond(), true, "nested project badge")
      equal(components.root_dir[1](), "󱉭  project", "root basename")
      vim.api.nvim_set_current_dir(directory .. "/project/src")
      equal(components.root_dir.cond(), true, "parent project badge")
      vim.b.trouble_lualine = false
      equal(components.symbols.cond(), false, "buffer breadcrumb opt-out")
      vim.bo.modified = false
      vim.api.nvim_buf_set_name(fixture, "")
      equal(components.pretty_path[1](self), "", "unnamed buffer path")
    end, debug.traceback)
    vim.api.nvim_set_current_dir(cwd)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_delete(fixture, { force = true })
    vim.fn.delete(directory, "rf")
    assert(checked, failure)
    local wk_config = require("which-key.config")
    assert(
      vim.wait(1000, function()
        return wk_config.loaded
      end),
      "which-key initialization timed out"
    )
    local wk = wk_config.options
    equal(wk.preset, "helix", "which-key preset")
    equal(wk.win.width, { min = 30, max = 60 }, "which-key width")
    equal(wk.win.padding, { 0, 1 }, "which-key padding")
    equal(wk.win.col, -1, "which-key right alignment")
    equal(wk.win.border, "single", "intentional Linux border")
    for _, key in ipairs({
      "<leader><space>",
      "<leader>/",
      "<leader>,",
      "<leader>ff",
      "<leader>fF",
      "<leader>fg",
      "<leader>sg",
      "<leader>sG",
      "<leader>e",
      "<leader>E",
      "<leader>p",
      "<leader>bp",
      "<leader>bd",
      "<leader>tr",
      "<leader>tt",
      "<leader>tT",
      "<leader>qs",
      "<leader>qS",
      "<leader>ql",
      "<leader>qd",
      "<leader>Gg",
      "<leader>Gf",
      "<leader>cr",
      "<leader>cf",
      "<leader>uf",
      "<leader>uF",
      "<leader>?",
      "<C-w><space>",
      "<leader>-",
      "<leader>|",
      "[b",
      "]b",
      "[d",
      "]d",
      "[e",
      "]e",
      "<C-a>",
      "g<C-a>",
    }) do
      mapping(key)
    end
    for _, mode in ipairs({ "i", "x", "n", "s" }) do
      mapping("<C-s>", mode)
    end
    for _, mode in ipairs({ "n", "x", "o" }) do
      mapping("<C-space>", mode)
    end
    for _, mode in ipairs({ "n", "x" }) do
      mapping("<leader>sw", mode)
      mapping("<leader>sr", mode)
    end
    equal(mapping("<leader>bp").rhs, "<cmd>BufferLineTogglePin<cr>", "pin must not cycle buffers")
    equal(mapping("<C-h>").rhs, "<C-w>h", "native split navigation, not tmux")
    equal(mapping("j", "x").expr, 1, "visual wrapped-line navigation")
    equal(mapping("<leader>cr").expr, 1, "rename prefills current word")

    -- Exercise dispatch while avoiding real tests, Git writes, or external tools.
    require("lz.n").trigger_load("neotest")
    local neotest = require("neotest")
    local run, called = neotest.run.run, {}
    neotest.run.run = function(arg)
      called[#called + 1] = arg == nil and "<nearest>" or arg
    end
    for _, key in ipairs({ "tr", "tt", "tT" }) do
      vim.api.nvim_feedkeys(vim.g.mapleader .. key, "xt", false)
    end
    neotest.run.run = run
    equal(called, { "<nearest>", vim.fn.expand("%"), vim.uv.cwd() }, "nearest/file/all test dispatch")

    local conform = require("conform")
    local format, format_calls = conform.format, 0
    conform.format = function(opts)
      equal(opts.lsp_format, "fallback", "format fallback")
      format_calls = format_calls + 1
    end
    local function save()
      vim.api.nvim_exec_autocmds("BufWritePre", { group = "Conform", buffer = 0 })
    end
    vim.g.autoformat = true
    vim.b.autoformat = true
    save()
    equal(format_calls, 1, "format-on-save enabled")
    mapping("<leader>uf").callback()
    save()
    equal(format_calls, 1, "global format toggle")
    mapping("<leader>uf").callback()
    mapping("<leader>uF").callback()
    save()
    equal(format_calls, 1, "buffer format toggle")
    mapping("<leader>uF").callback()
    save()
    equal(format_calls, 2, "format re-enabled")
    conform.format = format

    vim.cmd.enew()
    vim.bo.filetype = "markdown"
    equal(vim.wo.wrap, true, "Markdown wrap")
    equal(vim.wo.spell, true, "Markdown spelling")
    vim.bo.filetype = "json"
    equal(vim.wo.conceallevel, 0, "JSON conceal")
    local diagnostics = vim.diagnostic.config()
    equal(diagnostics.virtual_text.spacing, 4, "diagnostic spacing")
    equal(diagnostics.update_in_insert, false, "stable insert diagnostics")
    require("lz.n").trigger_load("blink-cmp")
    local blink = require("blink.cmp.config")
    equal(blink.keymap.preset, "enter", "Blink Enter preset")
    equal(type(blink.keymap["<A-y>"][1]), "function", "Minuet mapping must not be a nested list")
    equal(blink.completion.documentation.auto_show_delay_ms, 200, "completion documentation delay")
    equal(blink.cmdline.enabled, true, "command-line completion")
    local ai = require("mini.ai").config
    equal(ai.n_lines, 500, "text object search range")
    for _, key in ipairs({ "o", "f", "c", "t", "d", "e", "g", "u", "U" }) do
      assert(ai.custom_textobjects[key], "missing text object " .. key)
    end
    for _, case in ipairs({
      { "markdown", "[ ]", "[x]" },
      { "typescript", "let", "const" },
      { "text", "Monday", "Tuesday" },
    }) do
      vim.bo.filetype = case[1]
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { case[2] })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      vim.api.nvim_feedkeys(vim.keycode("<C-a>"), "xt", false)
      equal(vim.api.nvim_get_current_line(), case[3], case[1] .. " Dial increment")
    end
    for _, key in ipairs({ "<a-c>", "<a-t>", "<a-s>" }) do
      assert(Snacks.config.picker.win.input.keys[key], "missing picker action " .. key)
    end
    assert(type(require("trouble.sources.snacks").actions.trouble_open.action) == "function")
    print("Neovim parity checks passed")
  end, debug.traceback)
  if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end, 1000)
