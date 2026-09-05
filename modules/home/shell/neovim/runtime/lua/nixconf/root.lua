-- Shared root selection for navigation and the statusline.
return function(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local file = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf))
  local roots = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    local paths = {}
    for _, workspace in ipairs(client.config.workspace_folders or {}) do
      paths[#paths + 1] = vim.uri_to_fname(workspace.uri)
    end
    paths[#paths + 1] = client.root_dir
    for _, path in ipairs(paths) do
      path = vim.uv.fs_realpath(path)
      if file and path and (file == path or vim.startswith(file, path .. "/")) then
        roots[#roots + 1] = path
      end
    end
  end
  table.sort(roots, function(a, b)
    return #a > #b
  end)
  return roots[1] or vim.fs.root(file or vim.uv.cwd(), { ".git", "lua" }) or vim.uv.cwd()
end
