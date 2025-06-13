#
# ~/.bashrc - User-specific Bash configuration
#

# Only run if shell is interactive
[[ $- != *i* ]] && return

# --- Aliases ---
# Colorize common commands for better visibility
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Flatpak alias to always use --user flag on non-Btrfs systems
alias flatpak='flatpak --user'

# Shortcut to launch Hyprland under Wayland session
alias hypr='XDG_SESSION_TYPE=wayland exec Hyprland'

# --- Environment Variables ---
# Default editor for command line text editing
export EDITOR=/usr/bin/micro

# GTK theme for graphical apps
export GTK_THEME=Materia-dark

# --- Prompt ---
# PS1 defines the command prompt appearance
# \w = full current working directory path
# \$ = shows '#' for root, '$' for normal user
# Icon can be customized, examples: 󰞷 (penguin), , λ, etc.
PS1='󰞷 \w\$ '

# --- Functions ---

# Run a command in the background, redirecting output to a log file
background() {
  if [ $# -lt 1 ]; then
    echo "Usage: background <command> [args...]"
    return 1
  fi

  # Sanitize command name for log filename (replace '/' with '_')
  local cmd_name="${1//\//_}"

  # Run command detached from terminal, log output in ~/.cache/
  nohup "$@" > ~/.cache/"$cmd_name".log 2>&1 < /dev/null &

  echo "$1 started in background. Logs: ~/.cache/$cmd_name.log"
}
