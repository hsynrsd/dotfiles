# ── Runs for every shell ─────────────────────────────
fish_add_path ~/.local/bin ~/.cargo/bin

if type -q nvim
    set -gx EDITOR nvim
else
    set -gx EDITOR nano
end
set -gx VISUAL $EDITOR

# Colored man pages through bat
if type -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT -c
end

if status is-interactive
    set -g fish_greeting

    # ── Tools ────────────────────────────────────────
    type -q starship; and starship init fish | source

    if type -q fzf
        fzf --fish | source
        set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border --info=inline'
        if type -q fd
            set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
            set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
            set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git'
        end
        type -q bat; and set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    end

    # ── Smart abbreviations ──────────────────────────
    # .. → cd ../   ... → cd ../../   (any number of dots)
    function __multicd
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
    end
    abbr -a dotdot --regex '^\.\.+$' --function __multicd

    # !! → last command, anywhere on the line (e.g. "sudo !!")
    function __last_cmd
        echo $history[1]
    end
    abbr -a !! --position anywhere --function __last_cmd

    # ── Git ──────────────────────────────────────────
    abbr -a gs  git status -sb
    abbr -a ga  git add
    abbr -a gaa git add -A
    abbr -a gd  git diff
    abbr -a gds git diff --staged
    abbr -a gl  git log --oneline --graph --decorate -20
    abbr -a gsw git switch
    abbr -a gcb git switch -c
    abbr -a gp  git push
    abbr -a gpl git pull --rebase
    abbr -a gc  --set-cursor 'git commit -m "%"'

    # ── Files ────────────────────────────────────────
    type -q bat; and abbr -a cat 'bat --paging=never'
    if type -q eza
        abbr -a ls 'eza --icons --group-directories-first'
        abbr -a ll 'eza -la --icons --git --group-directories-first'
        abbr -a lt 'eza --tree --level=2 --icons'
    end

    function mkcd -d "Make a directory and cd into it"
        mkdir -p -- $argv[1]; and cd -- $argv[1]
    end

    # ── System / dev ─────────────────────────────────
    abbr -a up   'sudo dnf upgrade --refresh'
    abbr -a dnfi 'sudo dnf install'
    abbr -a dnfs 'dnf search'
    abbr -a va   'source .venv/bin/activate.fish'
    abbr -a mkv  'python -m venv .venv'
    type -q distrobox; and abbr -a kali 'distrobox enter kali'   # change to your container's name

    # zoxide goes last, as its docs recommend
    type -q zoxide; and zoxide init fish | source
end

