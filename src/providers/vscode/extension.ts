import { profileArgs } from './utils'

const extensionCache: Map<string, Set<string> | null> = new Map()

export function getExtensions(profileName: string): Set<string> {
    if (extensionCache.has(profileName)) {
        const cached = extensionCache.get(profileName)

        if (cached) return cached
    }

    const result = Bun.spawnSync(['code', ...profileArgs(profileName), '--list-extensions'])
    if (result.exitCode !== 0) {
        console.error('Failed to list VSCode extensions:', result.stderr.toString())

        return new Set()
    }

    const extensions = new Set(
        result.stdout
            .toString()
            .split('\n')
            .map((s) => s.trim().toLowerCase())
            .filter(Boolean),
    )
    extensionCache.set(profileName, extensions)

    return extensions
}

export function invalidateCache(profileName?: string): void {
    if (profileName) {
        extensionCache.delete(profileName)
    } else {
        extensionCache.clear()
    }
}
