import type { Context } from '../src/context'

export default (ctx: Context) => {
    ctx.brew.cask('visual-studio-code')

    const DEFAULT_SETTINGS = {
        "editor.fontSize": 12,
        "editor.tabSize": 4,
        'editor.formatOnSave': true,
        'terminal.integrated.fontFamily': 'JetBrainsMono Nerd Font',
    }

    ctx.vscode.settings('default', {
        mode: 'replace',
        values: {
            'editor.formatOnSave': true,
            '[lua]': {
                'editor.defaultFormatter': 'JohnnyMorganz.stylua',
            },
            'terminal.integrated.fontFamily': 'JetBrainsMono Nerd Font'
        },
    })

    ctx.vscode.profile('node', (p) => {
        p.settings('node', {
            mode: 'replace',
            values: {
                ...DEFAULT_SETTINGS,
                'editor.defaultFormatter': 'esbenp.prettier-vscode',
            },
        })

        p.extension('esbenp.prettier-vscode')
    })

    ctx.vscode.profile('node-modern', (p) => {
        p.settings('node-modern', {
            mode: 'replace',
            values: {
                ...DEFAULT_SETTINGS,
                'editor.defaultFormatter': 'biomejs.biome',
            },
        })

        p.extension('biomejs.biome')
    })
}
