vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load modules from this root-owned snapshot, not another user's home directory.
local config_root = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
vim.opt.rtp:prepend(config_root)
vim.g.velum_shared_config = config_root

-- Include user-installed database clients and .NET tools in editor terminals.
vim.env.PATH = vim.fn.expand("~/.local/share/velum/tools") .. ":" .. vim.fn.expand("~/.local/bin") .. ":" .. vim.fn.expand("~/.dotnet/tools") .. ":" .. vim.env.PATH

require("config.options")
require("config.keymaps")
require("config.lazy")
