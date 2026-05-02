#!/usr/bin/env fish
# doctor.fish — report which expected tools are present and which are missing.
# Returns nonzero if anything is missing.

set -l checks \
    fish git stow just \
    starship \
    fzf tmux zellij zoxide \
    fnm kubectl \
    lazygit lazydocker \
    alacritty \
    eza \
    fisher

function __have
    set -l name $argv[1]
    command -q $name; or functions -q $name
end

set -l missing
set -l present

for tool in $checks
    if __have $tool
        set -a present $tool
    else
        set -a missing $tool
    end
end

if test (count $present) -gt 0
    set_color green
    echo "Present:"
    set_color normal
    for t in $present
        echo "  [ok] $t"
    end
end

if test (count $missing) -gt 0
    set_color yellow
    echo
    echo "Missing:"
    set_color normal
    for t in $missing
        echo "  [--] $t"
    end
    exit 1
end

echo
set_color cyan; echo "All tools present."; set_color normal
