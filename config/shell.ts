import type { Context } from "../src/context";

export default (ctx: Context) => {
    // oh-my-posh
    ctx.brew.tap('jandedobbeleer/oh-my-posh')
    ctx.brew.install('oh-my-posh')

    // CLI tools
    ctx.brew.install('fd')
    ctx.brew.install('ripgrep')
    ctx.brew.install('jq')
    ctx.brew.install('btop')
    ctx.brew.install('tldr')
    ctx.brew.install('git-delta')
    ctx.brew.install('lazygit')
    ctx.brew.install('yazi')

    // Shell enhancements
    ctx.brew.install('eza')
    ctx.brew.install('bat')
    ctx.brew.install('fzf')
    ctx.brew.install('zoxide')
    ctx.brew.install('zsh-autosuggestions')
    ctx.brew.install('zsh-syntax-highlighting')
    ctx.brew.install('zsh-history-substring-search')

    // zshrc: symlink the config file, then source it from ~/.zshrc
    ctx.file.symlink('~/.config/shell', './dotfiles/shell')
    ctx.file.block('~/.zshrc', 'shell', 'source ~/.config/shell/shell.zsh')

    // bat config block
    ctx.file.block('~/.config/bat/config', 'bat', '--theme="catppuccin-mocha"\n--style="numbers,changes,header"')
}
