import type { Context } from '../src/context'

export default (ctx: Context) => {
    ctx.group('vscode', (g) => {
        g.brew.cask('visual-studio-code')

        g.vscode.settings('default', {
            mode: 'patch',
            values: {
                'editor.formatOnSave': true,
                '[lua]': {
                    'editor.defaultFormatter': 'JohnnyMorganz.stylua',
                },
                'terminal.integrated.fontFamily': 'JetBrainsMono Nerd Font'
            },
        })
    })
}
