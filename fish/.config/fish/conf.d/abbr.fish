if status is-interactive
    abbr --add cw center_window
    abbr --add cl clear

    abbr --add cc 'claude --dangerously-skip-permissions'
    abbr --add ccd 'claude --dangerously-skip-permissions'

        # Editors/Terminals
    abbr --add gho ghostty
    abbr --add wez wezterm
    abbr --add kit kitten
    abbr --add zela 'zellij a'
    abbr --add zels 'zellij -s'
    abbr --add zelk 'zellij k'
    abbr --add zelka 'zellij ka'
    abbr --add zeld 'zellij d'
    abbr --add zelda 'zellij da'
    abbr --add zell 'zellij ls'
    abbr --add muxa 'tmux attach'
    abbr --add muxaa 'tmux attach -t'
    abbr --add muxs 'tmux new-session -s'
    abbr --add muxk 'tmux kill-session -t'
    abbr --add muxka 'tmux kill-server'
    abbr --add muxl 'tmux list-sessions'
    abbr --add muxd 'tmux detach'

    abbr --add vim nvim
    abbr --add nv nvim
    abbr --add v nvim
    abbr --add nn 'nvim .'
    abbr --add vv 'nvim .'

    abbr --add hydra ~/Projects/Sites/hydra
end
