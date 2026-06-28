#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# PATH
export PATH="$HOME/.local/bin:$HOME/dotfiles/hypr/scripts:$PATH"

# Prompt
PS1='[\u@\h \W]\$ '

# Entorno
export GTK_THEME=Adwaita-dark
export XDG_CURRENT_DESKTOP=Hyprland
export EDITOR=nano
export VISUAL=nano
