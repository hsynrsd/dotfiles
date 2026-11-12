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
    fish_config theme choose catppuccin-mocha

    # System info when a new Konsole window/tab opens (not in nested shells, VS Code, etc.)
    if set -q KONSOLE_VERSION; and not set -q __fetched; and type -q fastfetch
        set -gx __fetched 1
        fastfetch
    end

    # ── Tools ────────────────────────────────────────
    type -q starship; and starship init fish | source

    if type -q fzf
        fzf --fish | source
        set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border=rounded --info=inline' \
            '--color=bg+:#313244,bg:-1,spinner:#7aa2f7,hl:#73b8c9,fg:#cdd6f4,header:#73b8c9' \
            '--color=info:#7aa2f7,pointer:#7aa2f7,marker:#73b8c9,fg+:#cdd6f4,prompt:#7aa2f7' \
            '--color=hl+:#73b8c9,selected-bg:#45475a,border:#6c7086,label:#cdd6f4'
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

    # ── Handy tools ──────────────────────────────────
    type -q lazygit;   and abbr -a lg lazygit
    type -q btop;      and abbr -a top btop
    type -q fastfetch; and abbr -a fetch fastfetch
    type -q tldr;      and abbr -a eg tldr          # eg tar → short examples
    abbr -a ports 'ss -tulpn'
    abbr -a myip 'curl -s ifconfig.me; echo'
    abbr -a df 'df -h -x tmpfs -x devtmpfs -x efivarfs'
    abbr -a du 'du -sh'
    function extract -d "Unpack any archive"
        switch $argv[1]
            case '*.tar.gz' '*.tgz';  tar xzf $argv[1]
            case '*.tar.xz' '*.txz';  tar xJf $argv[1]
            case '*.tar.zst';         tar --zstd -xf $argv[1]
            case '*.tar.bz2';         tar xjf $argv[1]
            case '*.tar';             tar xf $argv[1]
            case '*.zip';             unzip $argv[1]
            case '*.7z';              7z x $argv[1]
            case '*.rar';             unrar x $argv[1]
            case '*.gz';              gunzip $argv[1]
            case '*';                 echo "don't know how to extract $argv[1]"
        end
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


fish_add_path /home/hsynrsd/.spicetify
