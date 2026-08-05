# dotori

A Bun-powered library for building procedural, declarative macOS setup tools.

The configuration is regular TypeScript: evaluating it collects steps, then dotori plans or applies the resulting
queue in declaration order.

## Installation

Requirements:

- macOS
- Bun 1.3 or later
- Homebrew

```bash
bun add @mokyabun/dotori
```

## Configuration

Create a config module:

```ts
import { defineConfig, type Context } from '@mokyabun/dotori'

export default defineConfig((ctx: Context) => {
    ctx.brew.install('ripgrep')
    ctx.brew.cask('kitty')

    ctx.file.symlink('~/.config/kitty', './dotfiles/kitty')

    ctx.macos.plist('dock', 'com.apple.dock', {
        mode: 'patch',
        values: {
            autohide: true,
            'show-recents': false,
        },
        afterChange: [['killall', 'Dock']],
    })
})
```

Create the application entrypoint in the config repository:

```ts
import path from 'node:path'
import { createDotori, runCli } from '@mokyabun/dotori'
import config from './config'

const dotori = await createDotori({
    config,
    configCwd: path.join(import.meta.dir, 'config'),
})

await runCli(dotori)
```

`configCwd` is the base directory used to resolve relative paths declared by providers.

Add local scripts so the config repository controls the installed dotori version:

```json
{
  "scripts": {
    "dotori": "bun run main.ts",
    "plan": "bun run main.ts plan",
    "apply": "bun run main.ts apply",
    "clean": "bun run main.ts clean"
  }
}
```

## Usage

Run commands:

```bash
bun run plan
bun run apply
bun run clean
bun run dotori doctor
```

Run a single group:

```bash
bun run plan developer/vscode
bun run apply settings
```

## Customization

Split config into small modules and group related steps with `ctx.group()`.

```ts
export default defineConfig((ctx: Context) => {
    ctx.group('developer', (g) => {
        g.brew.install('node')
        g.vscode.extensions('default', ['biomejs.biome'])
    })

    ctx.group('settings', (g) => {
        g.macos.plist('finder', 'com.apple.finder', {
            mode: 'patch',
            values: {
                ShowPathbar: true,
                AppleShowAllFiles: true,
            },
            afterChange: [['killall', 'Finder']],
        })
    })
})
```

Available providers:

- `ctx.brew`: Homebrew formulae, casks, and taps
- `ctx.file`: symlinks, managed text blocks, JSON files, and downloads
- `ctx.macos`: defaults and plist files
- `ctx.vscode`: profiles, settings, extensions, keybindings, tasks, MCP, and snippets
- `ctx.launchd`: user LaunchAgents

Hooks can run after a step or group:

- `afterChange`: runs only when something changed
- `afterApply`: runs after apply, even when nothing changed

## Notes

- `clean` command removes items that dotori previously applied but are no longer declared.
- `patch` command keeps existing data and updates declared keys.
- `replace` command rewrites the target with the declared value.
- Pre-installed resources can be adopted into dotori state.
- Applied state is stored in `~/.local/share/dotori/state.sqlite`.
- Relative paths in config are resolved from the supplied `configCwd`.

## Library API

`createDotori()` evaluates the config once and returns an instance with `plan()`, `apply()`, and `clean()` methods.
`runCli()` is an optional adapter; applications can call those methods directly instead.

Low-level queue APIs (`createRuntime()`, `createQueue()`, `runPlan()`, `runApply()`, and `runClean()`) remain exported
for custom integrations.

## Development

```bash
bun run format
bun run build
bun run typecheck
bun run lint
bun run lint:fix
```
