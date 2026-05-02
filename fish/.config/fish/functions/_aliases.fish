# Colorize grep output (good for log files)
alias grep "grep --color=auto"
alias egrep "egrep --color=auto"
alias fgrep "fgrep --color=auto"
# gitnow
alias gcma commit-all
alias gcm commit
alias gs state

# Confirm before overwriting
alias cp "cp -Ri"
alias mv "mv -i"
alias rm "rm -i"

# Navigation
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias ...... "cd ../../../../.."
alias l "eza --long --all --header --git --icons --no-permissions --no-time --no-user --no-filesize --group-directories-first"
alias ll "eza -lagh --git --icons --group-directories-first"
alias la "eza -lagh --git --icons --group-directories-first --sort modified"
alias cll "clear; and eza --long --all --header --git --icons --no-permissions --no-time --no-user --no-filesize --group-directories-first"
alias tree "eza -Ta --icons --ignore-glob=\"node_modules|.git|.vscode|.DS_Store\""
alias ltd "eza -TaD --icons --ignore-glob=\"node_modules|.git|.vscode|.DS_Store\""

alias mux="tmux"
alias zel="zellij"