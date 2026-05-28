import type { Context } from 'dotori'

export default (ctx: Context) => {
    ctx.brew.cask('vesktop')
    ctx.brew.cask('parsec')
    ctx.brew.cask('brave-browser')
    ctx.brew.cask('linearmouse')
    ctx.brew.cask('jordanbaird-ice')
}
