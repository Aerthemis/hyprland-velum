return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", cmd = "DB" },
      { "kristijanhusak/vim-dadbod-completion", ft = "sql" },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "Database browser" },
      { "<leader>Da", "<cmd>DBUIAddConnection<cr>", desc = "Add database connection" },
      { "<leader>Df", "<cmd>DBUIFindBuffer<cr>", desc = "Find query in database browser" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_winwidth = 35
      vim.g.db_ui_execute_on_save = 0
      vim.g.db_ui_auto_execute_table_helpers = 0
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
      -- Route Atlas SRV URLs through Dadbod's MongoDB adapter unchanged.
      vim.g["db_adapter_mongodb#srv"] = "db#adapter#mongodb#"
      vim.g.db_ui_table_helpers = vim.tbl_deep_extend("keep", vim.g.db_ui_table_helpers or {}, {
        ["mongodb+srv"] = { List = "{table}.find()" },
      })
      local dbs = {}
      for name, env in pairs({ PostgreSQL = "PG_DATABASE_URL", MSSQL = "MSSQL_DATABASE_URL", MongoDB = "MONGODB_URI" }) do
        if vim.env[env] and vim.env[env] ~= "" then dbs[name] = vim.env[env] end
      end
      if next(dbs) then vim.g.dbs = vim.tbl_extend("keep", vim.g.dbs or {}, dbs) end
      vim.api.nvim_create_user_command("SqlDialect", function(opts)
        if not vim.tbl_contains({ "sql", "postgresql", "transactsql" }, opts.args) then
          vim.notify("Use :SqlDialect sql, postgresql, or transactsql", vim.log.levels.ERROR)
          return
        end
        vim.b.sql_dialect = opts.args
        vim.notify("SQL formatter dialect: " .. opts.args)
      end, {
        nargs = 1,
        complete = function() return { "sql", "postgresql", "transactsql" } end,
        desc = "Set SQL formatter dialect for the current buffer",
      })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = { sql = { "dadbod", "snippets", "buffer", "path" } },
        providers = { dadbod = { name = "Database", module = "vim_dadbod_completion.blink" } },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { sql = { "sql_formatter" } },
      formatters = {
        sql_formatter = {
          args = function(_, ctx)
            local config = vim.fs.find(".sql-formatter.json", { path = ctx.dirname, upward = true })[1]
            if config then return { "--config", config } end
            local dialect = vim.b[ctx.buf].sql_dialect
            if not dialect then
              local db = vim.b[ctx.buf].db
              if type(db) == "string" then
                if db:match("^postgres") then dialect = "postgresql"
                elseif db:match("^sqlserver:") then dialect = "transactsql" end
              end
            end
            return { "--language", dialect or "sql" }
          end,
        },
      },
    },
  },
}
