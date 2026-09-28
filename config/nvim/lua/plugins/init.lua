return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "night", transparent = false, styles = { comments = { italic = true }, keywords = { italic = true } } },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = function()
      if not vim.env.VELUM_BOOTSTRAP then vim.cmd("TSUpdate") end
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = vim.env.VELUM_BOOTSTRAP and {} or require("config.parsers"),
        auto_install = not vim.env.VELUM_BOOTSTRAP,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Search project" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Search help" },
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search buffer" },
    },
    opts = { defaults = { border = true, layout_strategy = "horizontal", sorting_strategy = "ascending", layout_config = { prompt_position = "top" } } },
  },

  { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, opts = { current_line_blame = false } },

  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.icons").setup()
      require("mini.pairs").setup()
      require("mini.surround").setup()
      require("mini.indentscope").setup({ symbol = "│" })
      require("mini.statusline").setup({ use_icons = true })
    end,
  },

  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "modern", delay = 300 } },

  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 }, menu = { border = "rounded" } },
      signature = { enabled = true, window = { border = "rounded" } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "lua" },
    },
    opts_extend = { "sources.default" },
  },

  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = { ui = { border = "rounded" } },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities({}, true) })
      require("config.languages").setup()
    end,
  },
}
