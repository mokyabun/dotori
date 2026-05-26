import type { Context } from '../src/context'

export default (ctx: Context) => {
    ctx.brew.cask('vesktop')
    ctx.brew.cask('parsec')
    ctx.brew.cask('brave-browser')
    ctx.brew.cask('linearmouse')
    ctx.brew.cask('jordanbaird-ice')
}
