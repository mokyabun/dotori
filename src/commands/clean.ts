import fs from 'node:fs'
import pc from 'picocolors'
import type { Queue } from '../context'
import { deleteAppliedState, getAllAppliedStates } from '../db'
import { cleanBrewCask, cleanBrewFormula, cleanBrewTap } from '../providers/brew'
import { cleanSymlink, cleanTextBlock } from '../providers/file'
import type { AppliedState } from '../types'
import { atomicWriteJson } from '../utils/atomic'
import { readPlist, resolvePlistPath, writePlist } from '../utils/plist'

export async function runClean(queue: Queue, filterGroupId?: string): Promise<void> {
    const desiredIds = new Set<string>()
    for (const node of queue) {
        if (node.type === 'step') {
            if (!filterGroupId) desiredIds.add(node.step.id)
        } else if (!filterGroupId || node.group.id === filterGroupId) {
            for (const step of node.group.steps) desiredIds.add(step.id)
        }
    }

    const toClean = getAllAppliedStates().filter((s) => !desiredIds.has(s.id))

    if (toClean.length === 0) {
        console.log(pc.green('Nothing to clean.'))
        return
    }

    console.log(pc.bold(`Cleaning ${toClean.length} item(s)...`))
    for (const applied of toClean) {
        await cleanItem(applied)
    }
}

async function cleanItem(applied: AppliedState): Promise<void> {
    const d = applied.details ?? {}
    console.log(`  ${pc.red('remove')}  ${applied.id}`)

    try {
        switch (applied.kind) {
            case 'brew.formula':
                if (typeof d.name === 'string') await cleanBrewFormula(d.name)
                break

            case 'brew.cask':
                if (typeof d.name === 'string') await cleanBrewCask(d.name)
                break

            case 'brew.tap':
                if (typeof d.repo === 'string') await cleanBrewTap(d.repo)
                break

            case 'file.symlink': {
                const { path: linkPath, target } = d as { path?: string; target?: string }
                if (linkPath && target) cleanSymlink(linkPath, target)
                break
            }

            case 'file.block': {
                const { path: filePath, marker } = d as { path?: string; marker?: string }
                if (filePath && marker) cleanTextBlock(filePath, marker)
                break
            }

            case 'file.json': {
                const { mode, path: filePath } = d as { mode?: string; path?: string }
                if (mode === 'replace' && filePath) {
                    try {
                        fs.unlinkSync(filePath)
                    } catch {}
                }
                break
            }

            case 'vscode.settings': {
                const { mode, path: filePath } = d as { mode?: string; path?: string }
                if (mode === 'replace' && filePath) atomicWriteJson(filePath, {})
                break
            }

            case 'vscode.extension': {
                const { extensionId } = d as { extensionId?: string }
                if (extensionId) Bun.spawnSync(['code', '--uninstall-extension', extensionId])
                break
            }

            case 'macos.plist': {
                const {
                    domain,
                    path: plistFilePath,
                    keys,
                } = d as {
                    domain?: string
                    path?: string
                    keys?: unknown
                }
                if (Array.isArray(keys) && (domain || plistFilePath)) {
                    const resolvedPath = plistFilePath ?? resolvePlistPath(domain as string)
                    const existing = readPlist(resolvedPath)
                    for (const k of keys as string[]) delete existing[k]
                    writePlist(resolvedPath, existing)
                } else {
                    console.log(pc.gray(`    skipping plist clean for ${applied.id} (no domain/keys)`))
                }
                break
            }

            case 'launchd.agent': {
                const { label, path: plistPath } = d as { label?: string; path?: string }
                if (label) Bun.spawnSync(['launchctl', 'unload', plistPath ?? ''])
                if (plistPath)
                    try {
                        fs.unlinkSync(plistPath)
                    } catch {}
                break
            }

            default:
                console.log(pc.gray(`    unknown kind ${applied.kind}, skipping`))
        }
    } catch (e) {
        console.error(pc.red(`    failed: ${e}`))
        return
    }

    deleteAppliedState(applied.id)
}
