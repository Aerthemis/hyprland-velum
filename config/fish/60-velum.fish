# Shared Fish defaults. Personal config.fish is loaded afterward and may override.
if command -q nvim
    set -gx EDITOR /usr/bin/nvim
    set -gx VISUAL /usr/bin/nvim
    set -gx SUDO_EDITOR /usr/bin/nvim
end

if status is-interactive
    set -g fish_greeting
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar clear
    alias claer clear
    if command -q pacman
        alias pamcan pacman
    end
    if command -q nvim
        alias vi nvim
        abbr --add --command sudo vi nvim
    end
    if test "$TERM" != linux; and test "$TERM" != dumb
        if command -q eza
            alias ls 'eza --icons=auto'
        end
        if command -q starship
            # A user can explicitly select another prompt via STARSHIP_CONFIG.
            if not set -q STARSHIP_CONFIG
                set -gx STARSHIP_CONFIG /etc/starship-velum.toml
            end
            function starship_transient_prompt_func
                starship module character
            end
            starship init fish | source
            enable_transience
        end
    end
    if test "$TERM" = xterm-kitty; and command -q kitten
        alias ssh 'kitten ssh'
    end
end
