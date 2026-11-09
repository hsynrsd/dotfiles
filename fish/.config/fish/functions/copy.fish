function copy --description 'Copy last command output (or piped input) to clipboard. -c: copy last command, -r: re-run & copy'
    if isatty stdin
        COPY_SHELL=fish termcopy $argv --hist $history[1..5]
    else
        termcopy $argv --hist $history[1..5]
    end
end
