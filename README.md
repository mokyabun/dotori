# dotori

Declarative macOS environment manager for Bun.

## Usage

```ts
import { defineConfig } from 'dotori'

export default defineConfig((dotori) => {
    dotori.brew.install('ripgrep')
    dotori.file.symlink('~/.config/example', './dotfiles/example')
})
```

```bash
bun run dotori plan
bun run dotori apply
bun run dotori clean
```

`dotori` is exposed as a library from `src/index.ts`; the CLI lives in `src/cli.ts`.
