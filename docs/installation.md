# Fish and Neovim on plain Arch

These scripts target a **booted Arch installation**, including a TTY-only VM.
Start with working networking, configured package mirrors, Git, and a normal
user with sudo access. They do not partition disks, create users, install a
compositor/login manager, or install the complete Velum desktop.

They use standard Arch packages and upstream plugins. No end-4, illogical-impulse,
ML4W, Caelestia, generated shell colors or files from another user's home are needed.

## Run in your VM

Clone the repository as your normal user after this milestone is pushed, or
copy the current working tree into the VM:

```bash
git clone https://github.com/Aerthemis/hyprland-velum.git
cd hyprland-velum

# Print the plan first; these commands do not change anything.
./scripts/setup-fish --dry-run --set-shell
./scripts/setup-nvim --dry-run --with-powershell

# Install, with pacman's normal confirmation prompt.
sudo ./scripts/setup-fish --set-shell
sudo ./scripts/setup-nvim --with-powershell
```

Both installers use `pacman -Syu --needed`: this performs a **full system upgrade**
as well as installing dependencies, avoiding partial upgrades. Exact package
lists are in `packages/fish.txt` and `packages/nvim.txt`.

Fish setup installs Fish, Starship, eza, Kitty, Neovim and a Nerd Font; it writes
shared Fish/prompt/Kitty defaults. `--set-shell` changes the selected user's login
shell. Log out and back in afterward. Kitty requires a graphical session to run;
Fish/Neovim work in the TTY. The Linux console intentionally retains a plain
Fish prompt because it lacks the terminal's fonts/color capabilities.

Neovim setup installs compiler/search tools, clipboard support, and Python,
Node.js, PHP, .NET and C/C++ runtimes. It then runs two stages as the target user:

1. Install/restore plugins to the repository's lockfile pins.
2. Build syntax parsers and install Mason language tools, waiting for completion.

Downloads need internet access and may take several minutes. Errors return a
nonzero status so incomplete setup is not reported as success. Use `:MasonLog`
and `:checkhealth` to diagnose a failed bootstrap, then rerun after fixing it.

`--with-powershell` installs Microsoft's PowerShell .NET tool in that account's
`~/.local/share/velum/tools`. Omit it to skip PowerShell support. Optional database
clients (`psql`, `sqlcmd`, `mongosh`) are not installed; see [the IDE guide](../config/nvim/IDE.md).
Projects may require older/additional .NET SDKs beyond Arch's current version.

## Options and accounts

- `--user NAME`: use an existing account; default is the user invoking sudo.
- `--root-shell`: Fish installer only; also make Fish root's login shell.
- `--skip-bootstrap`: Neovim installer only; defer plugin/parser/tool downloads.
- `--replace`: allow conflicting system files to be replaced after backup.
- `--dry-run`: no package commands, writes, shell changes or downloads.

To set root's Fish shell, run `sudo ./scripts/setup-fish --set-shell --root-shell`.
To fully provision root's editor separately, run
`sudo ./scripts/setup-nvim --user root --with-powershell` from the normal account.
Otherwise, other users download their own plugins on first launch and can run
`:Lazy restore` and `:IdeInstall` for tools.

Personal configs are never overwritten and take precedence. If a target user
already has Neovim init.lua/init.vim, automatic bootstrap is skipped to avoid
changing that user's plugins. Use a fresh account for clean-default testing.
All account-specific state uses standard XDG paths under the selected home;
custom XDG layouts require manual integration.

## Installed files, backups and reruns

| Component | Shared configuration |
| --- | --- |
| Fish | `/etc/fish/conf.d/60-velum.fish`, `/etc/starship-velum.toml` |
| Kitty | `/etc/xdg/kitty/kitty.conf` |
| Neovim | `/etc/xdg/nvim/init.lua`, Lua modules, bootstrap, lockfile and guide |

Arch's packaged Neovim sysinit.vim is preserved. Shared config is root-owned;
plugins, writable lockfiles, language tools, sessions, undo, history and database
connections belong to individual accounts. No user credentials are included.

Checksums in `/var/lib/velum/` identify installed files. Identical files are left
alone. An unmodified managed file can be updated; locally edited/unrelated files
require `--replace`. Changed files are backed up under unique
`/var/backups/velum-*` directories, preserving their original paths.
Installers do not remove packages or delete obsolete config files.

Rerunning Neovim bootstrap restores the repo's plugin pins for the selected user,
which may undo independent plugin updates. Package and Mason tool versions follow
upstream; this is not an entirely version-locked OS image.

## VM acceptance checklist

Offline checks pass, but **a complete fresh-Arch VM installation is not yet tested**.

1. Start with Arch, a normal sudo user, networking and Git, but no GUI.
2. Run both dry runs; confirm no system changes.
3. Install Fish with `--set-shell`; log in again and check aliases/editor defaults.
4. Install Neovim; confirm both bootstrap stages complete. Open files and test
   explorer, search, completion, syntax highlighting and formatting.
5. Inspect `:checkhealth`, `:Mason` and `:ConformInfo`.
6. Rerun both installers; confirm no duplicate settings or damaged ownership.
7. Edit a managed file; test refusal without `--replace` and backup with it.
8. Test a second account/root; verify separate data and history.
9. Interrupt networking during bootstrap; reconnect and test recovery by rerunning.
10. Once a GUI is installed, test Kitty fonts, Fish styling and clipboard behavior.

Development checks: `./scripts/check-setup` runs offline Bash/Fish/Lua/TOML/JSON
checks and regression tests. It requires Fish, Neovim and Python 3.11+ locally;
it never installs system packages/configuration or downloads plugins.
