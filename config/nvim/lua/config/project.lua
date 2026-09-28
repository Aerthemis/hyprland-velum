local M = {}
local terminals = {}

function M.root()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.bo.buftype ~= "" then return vim.fn.getcwd() end
  return vim.fs.root(path, { ".git", "pyproject.toml", "composer.json", "CMakeLists.txt", "package.json", "global.json" })
    or vim.fn.getcwd()
end

function M.set_root()
  local root = M.root()
  vim.api.nvim_set_current_dir(root)
  vim.notify("Project: " .. root)
end

function M.terminal()
  local root = M.root()
  local buf = terminals[root]
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then vim.api.nvim_win_hide(win); return end
    vim.cmd("botright 14split")
    vim.api.nvim_win_set_buf(0, buf)
  else
    vim.cmd("botright 14new")
    terminals[root] = vim.api.nvim_get_current_buf()
    vim.fn.jobstart(vim.o.shell, { term = true, cwd = root, on_exit = function() terminals[root] = nil end })
  end
  vim.cmd.startinsert()
end

return M
