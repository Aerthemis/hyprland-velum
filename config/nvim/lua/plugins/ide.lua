return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>fe", "<cmd>Neotree toggle<cr>", desc = "Project explorer" },
      { "<leader>fE", "<cmd>Neotree reveal<cr>", desc = "Reveal current file" },
    },
    opts = {
      window = { width = 32 },
      filesystem = { follow_current_file = { enabled = true }, hijack_netrw_behavior = "open_current" },
    },
  },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Project problems" },
      { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "File problems" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols outline" },
    },
    opts = {},
  },
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" }, desc = "Format code" },
      { "<leader>uf", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("Format on save: " .. (vim.g.disable_autoformat and "off" or "on"))
      end, desc = "Toggle format on save" },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
        sh = { "shfmt" }, bash = { "shfmt" },
        yaml = { "prettier" }, json = { "prettier" }, jsonc = { "prettier" },
        c = { "clang_format" }, cpp = { "clang_format" },
        php = { "php_cs_fixer" },
      },
      formatters = {
        php_cs_fixer = {
          -- Use the project's chosen rules; do not impose PHP defaults.
          condition = function(_, ctx)
            return vim.fs.root(ctx.filename, { ".php-cs-fixer.php", ".php-cs-fixer.dist.php" }) ~= nil
          end,
        },
      },
      format_on_save = function(buf)
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
    },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore project session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select session" },
    },
  },
  { "b0o/SchemaStore.nvim", lazy = true },
}
