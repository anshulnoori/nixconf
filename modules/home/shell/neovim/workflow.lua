local function map(lhs, rhs, desc)
  vim.keymap.set("n", "<leader>" .. lhs, rhs, { silent = true, desc = desc })
end
map("tr", function()
  require("neotest").run.run()
end, "Run Nearest (Neotest)")
map("tl", function()
  require("neotest").run.run_last()
end, "Run Last (Neotest)")
map("ta", function()
  require("neotest").run.attach()
end, "Attach to Test (Neotest)")
map("to", function()
  require("neotest").output.open({ enter = true, auto_close = true })
end, "Show Output (Neotest)")
map("tO", function()
  require("neotest").output_panel.toggle()
end, "Toggle Output Panel (Neotest)")
map("tS", function()
  require("neotest").run.stop()
end, "Stop (Neotest)")
map("tw", function()
  require("neotest").watch.toggle(vim.fn.expand("%"))
end, "Toggle Watch (Neotest)")
map("td", function()
  require("neotest").run.run({ strategy = "dap" })
end, "Debug Nearest")
map("qS", function()
  require("persistence").select()
end, "Select Session")
map("ql", function()
  require("persistence").load({ last = true })
end, "Restore Last Session")
map("qd", function()
  require("persistence").stop()
end, "Don't Save Current Session")
map("Gg", "<cmd>Gradle<cr>", "Gradle Projects")
map("Gf", "<cmd>GradleFavorites<cr>", "Gradle Favorite Commands")
for key, action in pairs({
  db = "toggle_breakpoint",
  dc = "continue",
  di = "step_into",
  ["do"] = "step_out",
  dO = "step_over",
  dl = "run_last",
  dP = "pause",
  dr = "repl.toggle",
  dt = "terminate",
  dj = "down",
  dk = "up",
  dg = "goto_",
}) do
  map(key, function()
    local dap = require("dap")
    if action == "repl.toggle" then
      dap.repl.toggle()
    else
      dap[action]()
    end
  end, "Debug: " .. action)
end
map("dB", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, "Breakpoint Condition")
map("du", function()
  require("dapui").toggle()
end, "Dap UI")
vim.keymap.set({ "n", "x" }, "<leader>de", function()
  require("dapui").eval()
end, { desc = "Eval", silent = true })
