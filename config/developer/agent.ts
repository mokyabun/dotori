import type { Context } from 'dotori'

export default (ctx: Context) => {
    ctx.brew.cask('claude-code')
    ctx.brew.cask('codex')
    ctx.brew.cask('codex-app')
}
