import type { Context } from 'dotori'

export default (ctx: Context) => {
    ctx.brew.cask('discord')
    ctx.brew.cask('parsec')
    ctx.brew.cask('brave-browser')
    ctx.brew.cask('linearmouse')
    ctx.brew.cask('jordanbaird-ice')
    ctx.brew.cask('bambu-studio')
    ctx.brew.cask('blender')
}
