# History
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Completions
autoload -Uz compinit && compinit

# Plugins
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey '^[[A' history-substring-search-up
bindkey '^[OA' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OB' history-substring-search-down

# Aliases
alias grep='rg'
alias l='eza -lha --icons --git --group-directories-first'

# Nix
if [[ "$(uname)" == "Darwin" ]]; then
    alias rebuild='sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname -s)'
    alias rebuild-update='nix flake update ~/.config/nix && sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname -s)'
else
    alias rebuild='sudo nixos-rebuild switch --flake ~/.config/nix#$(hostname -s)'
    alias rebuild-update='nix flake update ~/.config/nix && sudo nixos-rebuild switch --flake ~/.config/nix#$(hostname -s)'
fi
alias gc='nix-collect-garbage -d && sudo nix-collect-garbage -d'

# fzf (Ctrl+R: history / Ctrl+T: file / Alt+C: cd)
eval "$(fzf --zsh)"

# zoxide (replaces cd with smart jump)
eval "$(zoxide init --cmd cd zsh)"

# oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.config/shell/catppuccin_mocha.omp.json)"
