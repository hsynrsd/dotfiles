if status is-interactive
    set -g fish_greeting
    starship init fish | source
    zoxide init fish | source
    fzf --fish | source

    abbr -a gs git status
    abbr -a gc git commit -m
    abbr -a gp git push
    abbr -a cat bat
end

