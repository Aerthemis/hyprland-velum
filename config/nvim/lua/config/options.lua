local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3
opt.cmdheight = 0
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.splitbelow = true
opt.splitright = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.updatetime = 250
opt.timeoutlen = 400
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "", foldclose = "" }
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.confirm = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "php", "cs", "ps1" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 3, source = "if_many" },
  float = { border = "rounded", source = true },
  signs = {
    text = { [vim.diagnostic.severity.ERROR] = "󰅚", [vim.diagnostic.severity.WARN] = "󰀪", [vim.diagnostic.severity.INFO] = "󰋽", [vim.diagnostic.severity.HINT] = "󰌶" },
  },
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Briefly highlight copied text",
  callback = function() vim.hl.on_yank({ timeout = 180 }) end,
})
