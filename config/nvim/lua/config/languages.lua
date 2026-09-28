local M = {}

-- Runtime-dependent tools are installed once their runtime is available.
local packages = {
  { "pyright", "node" }, { "ruff" },
  { "bash-language-server", "node" }, { "shellcheck" }, { "shfmt" },
  { "yaml-language-server", "node" }, { "json-lsp", "node" }, { "prettier", "node" },
  { "intelephense", "node" }, { "php-cs-fixer", "php" },
  { "powershell-editor-services", "pwsh" },
  { "roslyn-language-server", "dotnet" },
  { "sql-formatter", "node" },
}
M.packages = packages

function M.install()
  local registry = require("mason-registry")
  registry.refresh(function(success)
    if not success then
      vim.schedule(function() vim.notify("Mason registry refresh failed; check :MasonLog", vim.log.levels.ERROR) end)
      return
    end
    vim.schedule(function()
      local missing = {}
      for _, spec in ipairs(packages) do
        if spec[2] and vim.fn.executable(spec[2]) == 0 then
          missing[spec[2]] = true
        elseif registry.has_package(spec[1]) then
          local package = registry.get_package(spec[1])
          if not package:is_installed() and not package:is_installing() then package:install() end
        else
          vim.notify("Mason package unavailable: " .. spec[1], vim.log.levels.WARN)
        end
      end
      if next(missing) then
        vim.notify("Missing runtimes: " .. table.concat(vim.tbl_keys(missing), ", ") .. ". Install them, then run :IdeInstall.", vim.log.levels.WARN)
      end
    end)
  end)
end

function M.setup()
  vim.lsp.config("pyright", {
    before_init = function(_, config)
      local root = config.root_dir or vim.fn.getcwd()
      for _, env in ipairs({ ".venv", "venv" }) do
        local python = root .. "/" .. env .. "/bin/python"
        if vim.fn.executable(python) == 1 then
          config.settings = vim.tbl_deep_extend("force", config.settings or {}, { python = { pythonPath = python } })
          break
        end
      end
    end,
    settings = { python = { analysis = { typeCheckingMode = "basic" } } },
  })
  vim.lsp.config("yamlls", { settings = { yaml = {
    schemaStore = { enable = false, url = "" },
    schemas = require("schemastore").yaml.schemas(),
  } } })
  vim.lsp.config("jsonls", { settings = { json = {
    schemas = require("schemastore").json.schemas(), validate = { enable = true },
  } } })
  vim.lsp.config("powershell_es", {
    bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
  })
  require("mason-lspconfig").setup({ automatic_enable = true })
  if vim.fn.executable("clangd") == 1 then vim.lsp.enable("clangd") end
  vim.api.nvim_create_user_command("IdeInstall", M.install, { desc = "Install IDE language tools" })
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.name == "ruff" then client.server_capabilities.hoverProvider = false end
    end,
  })
end

return M
