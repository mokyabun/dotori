import type { Context } from '../../src/context'

const BASE_EXTENSIONS = [
    'GitHub.copilot-chat',
    'Catppuccin.catppuccin-vsc',
    'thang-nm.catppuccin-perfect-icons',
    'EditorConfig.EditorConfig',
    'openai.chatgpt',
]

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
        'package.json': '*',
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

    'workbench.colorTheme': 'Catppuccin Mocha',
    'workbench.iconTheme': 'Catppuccin Perfect Mocha',

    'workbench.welcomePage.walkthroughs.openOnInstall': false,

    'chatgpt.openOnStartup': false,
}

export default (ctx: Context) => {
    ctx.brew.cask('visual-studio-code')

    ctx.vscode.settings('default', 'patch', {
        ...BASE_SETTINGS,
        '[lua]': {
            'editor.defaultFormatter': 'JohnnyMorganz.stylua',
        },
        '[nix]': {
            'editor.tabSize': 2,
        },
        '[json, jsonc]': {
            'editor.tabSize': 2,
        },
        '[yaml]': {
            'editor.tabSize': 2,
        },
    })
    ctx.vscode.extensions('default', BASE_EXTENSIONS)

    ctx.vscode.profile('node')
    ctx.vscode.settings('node', 'patch', {
        ...BASE_SETTINGS,
        'editor.defaultFormatter': 'esbenp.prettier-vscode',
        '[typescript, javascript, typescriptreact, javascriptreact, json, jsonc]': {
            'editor.defaultFormatter': 'esbenp.prettier-vscode',
        },
        'typescript.experimental.useTsgo': true,
        'svelte.enable-ts-plugin': true,
    })
    ctx.vscode.extensions('node', [
        ...BASE_EXTENSIONS,
        'esbenp.prettier-vscode',
        'dbaeumer.vscode-eslint',
        'TypeScriptTeam.native-preview',
        'svelte.svelte-vscode',
    ])

    ctx.vscode.profile('node-modern')
    ctx.vscode.settings('node-modern', 'patch', {
        ...BASE_SETTINGS,
        'editor.defaultFormatter': 'biomejs.biome',
        '[typescript, javascript, typescriptreact, javascriptreact, json, jsonc]': {
            'editor.defaultFormatter': 'biomejs.biome',
        },
        'editor.codeActionsOnSave': {
            'source.organizeImports.biome': 'explicit',
            'source.fixAll.biome': 'explicit',
        },
        'typescript.experimental.useTsgo': true,
        'svelte.enable-ts-plugin': true,
    })
    ctx.vscode.extensions('node-modern', [
        ...BASE_EXTENSIONS,
        'biomejs.biome',
        'TypeScriptTeam.native-preview',
        'svelte.svelte-vscode',
    ])
}
