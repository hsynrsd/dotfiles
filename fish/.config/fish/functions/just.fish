function just --wraps just --description 'just: use the project justfile, else ~/justfile'
    if command just --summary >/dev/null 2>&1
        command just $argv
    else
        command just --justfile ~/justfile --working-directory ~ $argv
    end
end
