import type { Context } from '../../src/context'

export default (ctx: Context) => {
    ctx.brew.cask('ghostty')
    ctx.brew.cask('font-jetbrains-mono-nerd-font')

    ctx.file.symlink('~/.config/ghostty', './dotfiles/ghostty')
}
