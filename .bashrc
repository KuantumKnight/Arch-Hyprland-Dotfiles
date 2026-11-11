# Bash configuration for the Arch Hyprland desktop.
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

# Show Fastfetch only in the first Kitty window when it is the only Kitty instance.
if [[ -n ${KITTY_WINDOW_ID:-} && ${KITTY_WINDOW_ID} == 1 && -z ${KITTY_FASTFETCH_SHOWN:-} ]] &&
   command -v fastfetch >/dev/null 2>&1; then
    kitty_instances=$(pgrep -xc kitty 2>/dev/null || :)
    if [[ $kitty_instances == 1 ]]; then
        export KITTY_FASTFETCH_SHOWN=1
        fastfetch
    fi
fi

# Starship everywhere; show user@host and suppress Python only in the home directory.
_starship_choose_config() {
    if [[ "$PWD" == "$HOME" ]]; then
        export STARSHIP_CONFIG="$HOME/.config/starship-home.toml"
    else
        export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    fi
}
if command -v starship >/dev/null 2>&1; then
    starship_precmd_user_func=_starship_choose_config
    _starship_choose_config
    eval "$(starship init bash)"
fi
