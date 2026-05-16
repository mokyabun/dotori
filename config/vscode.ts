import type { Context } from '../src/context'

export default (ctx: Context) => {
    ctx.group('vscode', (g) => {
        g.vscode.settings('default', {
            mode: 'patch',
            values: {
                'editor.formatOnSave': true,
            },
        })
    })
}
