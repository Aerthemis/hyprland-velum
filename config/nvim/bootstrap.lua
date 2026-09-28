-- Called by setup-nvim only. Fail visibly instead of claiming partial success.
local ok, err = xpcall(function()
  if vim.env.VELUM_BOOTSTRAP == "plugins" then
    require("lazy.manage").install({ wait = true, show = false, lockfile = true, clear = false })
    for name, plugin in pairs(require("lazy.core.config").plugins) do
      for _, task in ipairs(plugin._.tasks or {}) do
        assert(not task:has_errors(), "Plugin installation failed: " .. name)
      end
    end
    require("lazy.manage").restore({ wait = true, show = false })
    for name, plugin in pairs(require("lazy.core.config").plugins) do
      for _, task in ipairs(plugin._.tasks or {}) do
        assert(not task:has_errors(), "Plugin installation failed: " .. name)
      end
      assert(vim.uv.fs_stat(plugin.dir), "Plugin directory missing: " .. name)
    end
    print("Velum: pinned plugins installed; restarting for language tools.")
    return
  end

  local parsers = require("config.parsers")
  vim.cmd("TSInstallSync " .. table.concat(parsers, " "))
  local installed = require("nvim-treesitter.info").installed_parsers()
  for _, parser in ipairs(parsers) do
    assert(vim.tbl_contains(installed, parser), "Treesitter parser missing: " .. parser)
  end

  require("mason").setup()
  local registry = require("mason-registry")
  registry.refresh()
  local pending, failures = 0, {}
  for _, spec in ipairs(require("config.languages").packages) do
    if spec[2] and vim.fn.executable(spec[2]) == 0 then
      if spec[2] == "pwsh" then
        print("PowerShell tools skipped; rerun setup-nvim with --with-powershell to enable them.")
      else
        error("Missing runtime: " .. spec[2])
      end
    else
      assert(registry.has_package(spec[1]), "Mason package not found: " .. spec[1])
      local package = registry.get_package(spec[1])
      if not package:is_installed() then
        pending = pending + 1
        package:install({}, function(success)
          if not success then table.insert(failures, spec[1]) end
          pending = pending - 1
        end)
      end
    end
  end
  assert(vim.wait(20 * 60 * 1000, function() return pending == 0 end, 100), "Language-tool installation timed out; see :MasonLog")
  assert(#failures == 0, "Failed language tools: " .. table.concat(failures, ", "))
  print("Velum: parsers and language tools installed.")
end, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
