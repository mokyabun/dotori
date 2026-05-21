import fs from 'node:fs'
import path from 'node:path'
import type { Context, Queue } from './context'
import { createContext } from './context'

type ConfigFn = (ctx: Context) => void

function resolveConfigPath(configPath: string): string {
    const resolved = path.resolve(configPath)
    if (fs.existsSync(resolved)) return resolved
    // Fallback: try adding .ts extension (Bun projects often omit it in the default)
    const withTs = resolved.endsWith('.ts') ? resolved : `${resolved}.ts`
    if (fs.existsSync(withTs)) return withTs
    throw new Error(`Config file not found: ${resolved}`)
}

export async function loadConfig(configPath: string): Promise<Queue> {
    const resolved = resolveConfigPath(configPath)

    const queue: Queue = []
    const ctx = createContext(queue, path.dirname(resolved))

    const mod = await import(resolved)
    const fn: ConfigFn = mod.default ?? mod
    if (typeof fn !== 'function') {
        throw new Error(`Config must export a default function`)
    }

    fn(ctx)
    return queue
}
