#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1=' \w\$ '  # 🐧 Tux in the prompt
export EDITOR=/usr/bin/micro
export GTK_THEME=Materia-dark
alias hypr='XDG_SESSION_TYPE=wayland exec Hyprland'

# Automatically apply --user flag for Flatpak in non-Btrfs systems
alias flatpak='flatpak --user'

background() {
  if [ $# -lt 1 ]; then
    echo "Usage: background <command> [args...]"
    return 1
  fi
  # Run the command with all arguments, redirect output, in background detached from terminal
  nohup "$@" > ~/.cache/${1//\//_}.log 2>&1 < /dev/null &
  echo "$1 started in background."
}
