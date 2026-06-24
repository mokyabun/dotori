set -g fish_greeting
set -g fish_autosuggestion_enabled 1
set -g fish_color_autosuggestion 6c7086
set -g fish_color_command 89b4fa
set -g fish_color_param cdd6f4
set -g fish_color_error f38ba8
set -g fish_color_quote a6e3a1
set -g fish_color_redirection f5c2e7
set -g fish_color_operator f9e2af

set -gx FZF_DEFAULT_OPTS '--height=40% --layout=reverse --border=rounded --info=inline --prompt="> " --pointer=">" --marker="+"'

alias grep='rg'
alias l='eza -lha --icons --git --group-directories-first'
alias la='eza -la --icons --git --group-directories-first'
alias lt='eza --tree --level=2 --icons --git --group-directories-first'
alias dir-size='du -sh'
alias biggest='du -ah . 2>/dev/null | sort -rh | head -50'
alias recent='eza -la --icons --git --sort=modified --reverse'
alias ports='lsof -nP -iTCP -sTCP:LISTEN'
alias path-lines='printf "%s\n" $PATH'
alias mkdirp='mkdir -p'
alias serve='python3 -m http.server'
alias rls='rsync -navi --delete'

function dir-sizes
    find . -maxdepth 1 -mindepth 1 -exec du -sh {} + 2>/dev/null | sort -h
end

function rcp
    rsync -ah --info=progress2 $argv
end

function rmirror
    rsync -ah --delete --info=progress2 $argv
end

function rdry
    rsync -ahnvi --delete $argv
end

if type -q fzf
    fzf --fish | source
end

if type -q starship
    starship init fish | source
end
