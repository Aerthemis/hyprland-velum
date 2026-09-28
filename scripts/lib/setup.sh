#!/usr/bin/env bash
# Shared by the Arch installers; do not execute directly.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
dry_run=false
replace=false
bootstrap=true
set_shell=false
root_shell=false
with_powershell=false
target_user="${SUDO_USER:-$(id -un)}"
state_dir=/var/lib/velum

usage() {
    cat <<EOF
Usage: sudo ./scripts/setup-$component [options]
  --dry-run          Print actions only; no root or package installation needed
  --user NAME        Account for per-user setup (default: invoking sudo user)
  --replace          Back up and replace conflicting system configuration files
  --set-shell        Fish: make Fish the target user's login shell
  --root-shell       Fish: also make Fish root's login shell
  --skip-bootstrap   Neovim: install config/packages but defer plugin downloads
  --with-powershell  Neovim: install the PowerShell .NET tool for the target user
  --help             Show this help
EOF
}

parse_args() {
    while (( $# )); do
        case "$1" in
            --dry-run) dry_run=true ;;
            --replace) replace=true ;;
            --user) (( $# >= 2 )) || { echo '--user requires a name' >&2; return 2; }; target_user="$2"; shift ;;
            --set-shell) [[ "$component" == fish ]] || return 2; set_shell=true ;;
            --root-shell) [[ "$component" == fish ]] || return 2; root_shell=true ;;
            --skip-bootstrap) [[ "$component" == nvim ]] || return 2; bootstrap=false ;;
            --with-powershell) [[ "$component" == nvim ]] || return 2; with_powershell=true ;;
            --help|-h) usage; exit 0 ;;
            *) printf 'Unknown option: %s\n' "$1" >&2; return 2 ;;
        esac
        shift
    done
    [[ "$target_user" != -* && -n "$target_user" ]] || return 2
    local entry
    entry="$(getent passwd "$target_user")" || { echo 'Target account does not exist.' >&2; return 1; }
    IFS=: read -r target_user _ target_uid _ _ target_home _ <<< "$entry"
    [[ "$target_home" == /* && "$target_home" != / ]] || { echo 'Invalid target home directory.' >&2; return 1; }
    if [[ "$target_uid" == 0 && "${SUDO_USER:-}" == '' && "$dry_run" == false ]]; then
        echo 'Run via sudo from your normal account (or explicitly use a non-root --user).' >&2
        return 1
    fi
    if ! "$dry_run"; then
        (( EUID == 0 )) || { echo 'Run this installer using sudo, or use --dry-run.' >&2; return 1; }
        . /etc/os-release
        [[ "${ID:-}" == arch ]] || { echo 'This installer targets Arch Linux.' >&2; return 1; }
        command -v pacman >/dev/null
    fi
}

run() {
    printf ' +'; printf ' %q' "$@"; printf '\n'
    if ! "$dry_run"; then "$@"; fi
}

packages() {
    local list=() package
    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" == \#* ]] || list+=("$package")
    done < "$repo_dir/packages/$component.txt"
    # Full upgrade avoids unsupported partial upgrades; keep pacman's confirmation.
    run pacman -Syu --needed "${list[@]}"
}

sources=()
destinations=()
add_file() { sources+=("$1"); destinations+=("$2"); }
add_tree() {
    local file
    while IFS= read -r -d '' file; do
        add_file "$file" "$2/${file#"$1/"}"
    done < <(find "$1" -type f -print0 | sort -z)
}

preflight() {
    local i dest current recorded
    manifest="$state_dir/$component.sha256"
    # Check every destination before installing packages or writing configuration.
    for i in "${!sources[@]}"; do
        dest="${destinations[i]}"
        if [[ -L "$dest" ]]; then
            echo "Refusing a symlink destination: $dest" >&2; return 1
        fi
        [[ ! -e "$dest" || -f "$dest" ]] || { echo "Not a regular file: $dest" >&2; return 1; }
        if [[ -f "$dest" ]] && ! cmp -s "${sources[i]}" "$dest"; then
            current="$(sha256sum "$dest")"
            recorded=false
            if [[ -f "$manifest" ]] && grep -Fxq -- "$current" "$manifest"; then recorded=true; fi
            if ! "$recorded" && ! "$replace"; then
                echo "Existing/modified config: $dest. Review it, then use --replace to back it up and replace it." >&2
                return 1
            fi
        fi
    done
}

install_files() {
    local i dest backup='' tmp
    for i in "${!sources[@]}"; do
        dest="${destinations[i]}"
        if [[ -f "$dest" ]] && cmp -s "${sources[i]}" "$dest"; then continue; fi
        if [[ -e "$dest" ]]; then
            if [[ -z "$backup" ]]; then
                run install -d -m 755 /var/backups
                if "$dry_run"; then backup="/var/backups/velum-$component.DRY-RUN";
                else backup="$(mktemp -d "/var/backups/velum-$component.XXXXXXXX")"; fi
                printf 'Backup: %s\n' "$backup"
            fi
            run cp --parents -a -- "$dest" "$backup/"
        fi
        run install -D -o root -g root -m 644 -- "${sources[i]}" "$dest"
    done
    if ! "$dry_run"; then
        install -d -m 755 "$state_dir"
        tmp="$(mktemp "$state_dir/.manifest.XXXXXXXX")"
        sha256sum "${destinations[@]}" > "$tmp"
        chmod 644 "$tmp"
        mv -- "$tmp" "$manifest"
    fi
}

as_user() {
    # Package managers and Neovim state must use the target account, never sudo's HOME.
    run runuser -u "$target_user" -- env -u VIMINIT -u EXINIT -u MYVIMRC -u NVIM_APPNAME \
        HOME="$target_home" XDG_CONFIG_HOME="$target_home/.config" \
        XDG_DATA_HOME="$target_home/.local/share" XDG_STATE_HOME="$target_home/.local/state" \
        XDG_CACHE_HOME="$target_home/.cache" XDG_CONFIG_DIRS=/etc/xdg \
        PATH="$target_home/.local/share/velum/tools:/usr/local/bin:/usr/bin" "$@"
}
