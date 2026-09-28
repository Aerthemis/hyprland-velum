local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>confirm quit<CR>", { desc = "Quit" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })

map("n", "<leader>tt", function() require("config.project").terminal() end, { desc = "Project terminal" })
map("n", "<leader>fp", function() require("config.project").set_root() end, { desc = "Use current project root" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP shortcuts",
  callback = function(event)
    local function lsp(lhs, rhs, desc) map("n", lhs, rhs, { buffer = event.buf, desc = desc }) end
    lsp("gd", vim.lsp.buf.definition, "Go to definition")
    lsp("gr", vim.lsp.buf.references, "References")
    lsp("K", vim.lsp.buf.hover, "Hover documentation")
    lsp("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    lsp("<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})
