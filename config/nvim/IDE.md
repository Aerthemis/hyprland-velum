# Coding projects in Neovim

Open Neovim from a project directory: `cd /path/to/project && nvim .`.
The leader key is **Space**. Press Space and pause to see available shortcuts.

| Shortcut | Action |
| --- | --- |
| Space f e | Toggle project explorer |
| Space f E | Reveal the current file in the explorer |
| Space f f / Space f g | Find files / search project text |
| Space f b | Switch open buffers |
| Space f p | Set working directory to the current file's project root |
| gd / gr / K | Definition / references / documentation |
| Space r n / Space c a | Rename symbol / code action |
| Space x x / Space x d | Known project diagnostics / current-file diagnostics |
| Space c s | Symbols outline |
| Space c f | Format file or selection |
| Space u f | Toggle automatic formatting on save |
| Space t t | Toggle terminal for this project |
| Esc Esc (terminal mode) | Return to normal mode |
| Space q s / Space q l | Restore this project's session / last session |
| Space q S | Choose a saved session |
| Space q q | Quit (changed from Space q to accommodate sessions) |

Sessions save automatically after opening a file. Restore them explicitly with the
shortcuts above. Project search and sessions use the working directory; launch
Neovim in the project root, or use Space f p.

## Language tools

`:Mason` shows installation status. `:IdeInstall` installs missing tools once
their runtimes are available. Restart Neovim after installing runtimes.
`:checkhealth vim.lsp` shows server status; `:ConformInfo` shows formatters.

The setup script installs the standard Arch runtimes. To provision them manually:

```sh
sudo pacman -S --needed nodejs npm php dotnet-sdk
dotnet tool install --global PowerShell
```

The PowerShell command uses Microsoft's published .NET tool. Neovim adds
`~/.dotnet/tools` to its PATH. Then run `:IdeInstall` and wait for `:Mason` to
finish. Restart Neovim to activate all newly installed servers.

- Python: Pyright plus Ruff; `.venv/bin/python` or `venv/bin/python` is selected
  automatically within the detected project. Ruff formats on save.
- Bash: Bash Language Server plus ShellCheck; shfmt formats on save.
- YAML/JSON: language servers with SchemaStore schemas; Prettier formats on save.
- PHP: Intelephense; PHP-CS-Fixer runs when the project has `.php-cs-fixer.php`
  or `.php-cs-fixer.dist.php`. Project-local formatter binaries take precedence.
- C/C++: the system clangd and clang-format. For accurate includes and compiler
  flags, generate `compile_commands.json` (for CMake, use
  `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`) and make it discoverable by clangd.
- C#: Roslyn via Mason; the project requires its matching .NET SDK. C# formatting
  uses the language server. Razor-specific integration is not configured.
- PowerShell: PowerShell Editor Services; formatting uses the language server.

Project diagnostics show what language servers have reported; some servers only
analyze opened files. Use the project terminal for full test/lint/build commands.
Debug adapters and project-specific test runners are not configured.

Formatting follows repository configuration such as `.clang-format`, Ruff and
Prettier settings. To disable autoformat for one buffer:
`:lua vim.b.disable_autoformat = true`.

Plugin and language-tool versions are managed by the installer and per-user state.

## SQL: PostgreSQL and Microsoft SQL Server

- `Space D u`: database browser (capital D).
- `Space D a`: add a database connection.
- `Space D f`: locate the current query in the browser.
- `Space S`: execute a DBUI query, or its visual selection (capital S).
- `Space c f`: format SQL; format-on-save also applies.

Database queries execute explicitly, not when you save. Open a connection and
create a query from the database browser to get schema/table/column completion
through Dadbod. Unconnected SQL files still have snippets and buffer completion.
No standalone SQL language server or SQL diagnostics are configured.

Database clients are optional and not installed by the Velum script. Install
PostgreSQL's `psql` via Arch's `postgresql-libs`, and Microsoft's `sqlcmd` from
https://github.com/microsoft/go-sqlcmd/releases if needed. Node.js/npm are
installed by the setup script for SQL formatting.

Use `:DBUIAddConnection` with URLs shaped like:

```text
postgresql://USER:PASSWORD@HOST:5432/DATABASE
sqlserver://USER:PASSWORD@HOST:1433/DATABASE
```

Alternatively, launch Neovim with `PG_DATABASE_URL` and/or `MSSQL_DATABASE_URL`
set in your environment. Saved connections from DBUI are stored locally under
`~/.local/share/nvim/db_ui`; URL passwords are stored as plain text there.
No connections or credentials have been added by this setup.

SQL Formatter is installed through Mason; `:IdeInstall` can reinstall it if needed.
Set a buffer's dialect with `:SqlDialect postgresql` or
`:SqlDialect transactsql`. DBUI connection URLs select the dialect automatically
when available; otherwise the formatter defaults to standard SQL.

For a lasting project setting, create `.sql-formatter.json` in the project root:

```json
{ "language": "postgresql", "keywordCase": "upper" }
```

Use `"transactsql"` for SQL Server projects. This project file takes precedence
over the buffer dialect. SQL syntax highlighting uses the shared SQL parser;
it is not a full PostgreSQL/T-SQL validator.

## MongoDB

MongoDB uses the same database browser (`Space D u`). The optional `mongosh`
client can be installed for your user with
`npm install --global --prefix ~/.local mongosh`.

Use `Space D a` to add a connection, or set `MONGODB_URI` before starting Neovim.
Both standard and Atlas SRV connection strings are supported:

```text
mongodb://USER:PASSWORD@HOST:27017/DATABASE?authSource=admin
mongodb+srv://USER:PASSWORD@CLUSTER.mongodb.net/DATABASE
```

MongoDB queries open as JavaScript and results as JSON. For example:

```javascript
db.users.find({ active: true }).limit(20)
```

Use `Space S` to execute the query or visual selection in a DBUI query buffer.
Saving does not execute it. The browser lists collections; live MongoDB document
field completion is not provided by the SQL completion source. No connection
credentials are included in this configuration.
