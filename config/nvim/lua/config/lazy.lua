local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local fresh = not vim.uv.fs_stat(lazypath)
if fresh then
  local output = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then error("Could not install lazy.nvim:\n" .. output) end
end
if fresh or vim.env.VELUM_BOOTSTRAP == "plugins" then
  local pins = vim.json.decode(table.concat(vim.fn.readfile(vim.g.velum_shared_config .. "/lazy-lock.json"), "\n"))
  local pin = assert(pins["lazy.nvim"].commit)
  vim.fn.system({ "git", "-C", lazypath, "cat-file", "-e", pin })
  if vim.v.shell_error ~= 0 then
    local output = vim.fn.system({ "git", "-C", lazypath, "fetch", "origin", pin })
    if vim.v.shell_error ~= 0 then error("Could not fetch pinned lazy.nvim: " .. output) end
  end
  local output = vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", pin })
  if vim.v.shell_error ~= 0 then error("Could not select pinned lazy.nvim: " .. output) end
end
vim.opt.rtp:prepend(lazypath)

-- The system snapshot is read-only; each user manages a private lockfile.
local lockfile = vim.fn.stdpath("data") .. "/velum/lazy-lock.json"
if vim.fn.filereadable(lockfile) == 0 or vim.env.VELUM_BOOTSTRAP == "plugins" then
  vim.fn.mkdir(vim.fn.fnamemodify(lockfile, ":h"), "p")
  local source = vim.g.velum_shared_config .. "/lazy-lock.json"
  if vim.fn.filereadable(source) == 1 then
    vim.fn.writefile(vim.fn.readfile(source), lockfile)
  end
end

require("lazy").setup({
  lockfile = lockfile,
  performance = { rtp = { paths = { vim.g.velum_shared_config } } },
  spec = { { import = "plugins" } },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = not vim.env.VELUM_BOOTSTRAP, notify = false },
  change_detection = { notify = false },
  ui = { border = "rounded" },
})
