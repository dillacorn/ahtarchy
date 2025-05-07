#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='\w\ '
export EDITOR=/usr/bin/micro
export GTK_THEME=Materia-dark
alias hypr='XDG_SESSION_TYPE=wayland exec Hyprland'

# Automatically apply --user flag for Flatpak in non-Btrfs systems
alias flatpak='flatpak --user'