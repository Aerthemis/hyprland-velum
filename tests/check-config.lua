local root = assert(arg[1])
for _, path in ipairs(vim.fn.glob(root .. "/**/*.lua", false, true)) do
  assert(loadfile(path))
end
assert(type(vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))) == "table")
print("Neovim Lua and plugin lockfile parse successfully.")
