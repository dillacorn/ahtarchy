#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

fastfetch --config ~/.config/fastfetch/tty_compatible.jsonc

echo -e "\033[1;34mTo start hype, type: \033[1;31mhypr\033[0m"

# Function to generate a random message
add_random_fun_message() {
  fun_messages=("cacafire" "cmatrix" "aafire" "sl" "asciiquarium" "figlet TTY is cool")
  RANDOM_FUN_MESSAGE=${fun_messages[$((RANDOM % ${#fun_messages[@]}))]}
  echo -e "\033[1;33mFor some fun, try running \033[1;31m$RANDOM_FUN_MESSAGE\033[1;33m!\033[0m"
}

# Call the random fun message function on login
add_random_fun_message
