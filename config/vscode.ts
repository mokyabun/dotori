import type { Context } from '../src/context'

const BASE_SETTINGS = {
    'editor.fontSize': 12,
    'editor.tabSize': 4,

    'editor.formatOnSave': true,
    'editor.minimap.enabled': false,
    'editor.bracketPairColorization.enabled': true,
    'editor.guides.bracketPairs': 'active',

    'editor.stickyScroll.enabled': true,
    'editor.cursorBlinking': 'smooth',

    'editor.linkedEditing': true,
    'editor.renderWhitespace': 'boundary',

    'editor.inlayHints.enabled': 'onUnlessPressed',
    'editor.suggestSelection': 'first',
    'editor.snippetSuggestions': 'top',
    'editor.wordBasedSuggestions': 'off',
    'editor.acceptSuggestionOnEnter': 'smart',

    'files.trimTrailingWhitespace': true,
    'files.insertFinalNewline': true,

    'terminal.integrated.fontFamily': 'JetBrainsMono Nerd Font',

    'workbench.startupEditor': 'none',
    'workbench.editor.enablePreview': false,
    'workbench.tree.indent': 16,

    'explorer.confirmDelete': false,
    'explorer.confirmDragAndDrop': false,

    'explorer.fileNesting.enabled': true,
    'explorer.fileNesting.patterns': {
        'package.json': 'package-lock.json, bun.lock, pnpm-lock.yaml, yarn.lock',
        '*.ts': '${capture}.test.ts, ${capture}.spec.ts',
        '*.js': '${capture}.test.js, ${capture}.spec.js',
    },

    'git.autofetch': true,
    'git.confirmSync': false,

    'search.exclude': {
        '**/node_modules': true,
        '**/dist': true,
        '**/.git': true,
    },
}

export default (ctx: Context) => {
    ctx.brew.cask('visual-studio-code')

    ctx.vscode.profile('default', {
        settings: {
            mode: 'replace',
            values: {
                ...BASE_SETTINGS,
                '[lua]': {
                    'editor.defaultFormatter': 'JohnnyMorganz.stylua',
                },
                '[nix]': {
                    'editor.tabSize': 2,
                },
                '[json][jsonc]': {
                    'editor.tabSize': 2,
                },
                '[yaml]': {
                    'editor.tabSize': 2,
                },
            },
        },
        extensions: ['GitHub.copilot-chat'],
    })

    ctx.vscode.profile('node', {
        settings: {
            mode: 'replace',
            values: {
                ...BASE_SETTINGS,
                'editor.tabSize': 2,
                'editor.defaultFormatter': 'esbenp.prettier-vscode',
                '[typescript][javascript][typescriptreact][javascriptreact]': {
                    'editor.defaultFormatter': 'esbenp.prettier-vscode',
                },
            },
        },
        extensions: [
            'GitHub.copilot-chat',
            'esbenp.prettier-vscode',
            'dbaeumer.vscode-eslint',
            'TypeScriptTeam.native-preview',
        ],
    })

    ctx.vscode.profile('node-modern', {
        settings: {
            mode: 'replace',
            values: {
                ...BASE_SETTINGS,
                'editor.tabSize': 2,
                'editor.defaultFormatter': 'biomejs.biome',
                '[typescript][javascript][typescriptreact][javascriptreact][json][jsonc]': {
                    'editor.defaultFormatter': 'biomejs.biome',
                },
                'editor.codeActionsOnSave': {
                    'source.organizeImports.biome': 'explicit',
                    'source.fixAll.biome': 'explicit',
                },
            },
        },
        extensions: ['GitHub.copilot-chat', 'biomejs.biome', 'TypeScriptTeam.native-preview'],
    })
}
