import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import type { Step, PlanContext, ApplyContext, PlanResult, StepHooks } from '../types'
import { run } from '../utils/shell'
import { jsonPatch, removeKeys } from '../utils/json'
import { atomicWriteJson } from '../utils/atomic'

type SettingsMode = 'patch' | 'replace'

const SETTINGS_PATH = path.join(os.homedir(), 'Library', 'Application Support', 'Code', 'User', 'settings.json')

export class VscodeProvider {
    constructor(private readonly push: (step: Step) => void) {}

    settings(
        suffix: string,
        options: { mode: SettingsMode; values: Record<string, unknown>; hooks?: StepHooks },
    ): void {
        this.push(this.settingsStep(suffix, options.mode, options.values, options.hooks))
    }

    extension(extensionId: string): void {
        this.push(this.extensionStep(extensionId))
    }

    private settingsStep(suffix: string, mode: SettingsMode, values: Record<string, unknown>, hooks?: StepHooks): Step {
        const id = `vscode.settings.${suffix}`

        function readSettings(): Record<string, unknown> {
            try {
                return JSON.parse(fs.readFileSync(SETTINGS_PATH, 'utf8'))
            } catch {
                return {}
            }
        }

        return {
            id,
            kind: 'vscode.settings',
            title: `vscode settings ${mode} (${suffix})`,
            hooks,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const existing = readSettings()

                if (mode === 'replace') {
                    if (JSON.stringify(existing) === JSON.stringify(values)) {
                        return applied
                            ? { action: 'noop', message: 'vscode settings already correct', changed: false }
                            : { action: 'adopt', message: 'vscode settings already correct (adopt)', changed: false }
                    }
                    return { action: 'update', message: 'will replace vscode settings', changed: true }
                }

                const { changedKeys } = jsonPatch(existing, values)
                if (changedKeys.length === 0) {
                    return applied
                        ? { action: 'noop', message: 'vscode settings already correct', changed: false }
                        : { action: 'adopt', message: 'vscode settings already correct (adopt)', changed: false }
                }
                return {
                    action: 'update',
                    message: `will patch vscode settings (keys: ${changedKeys.join(', ')})`,
                    changed: true,
                }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create' || plan.action === 'update') {
                    const existing = readSettings()
                    let result: Record<string, unknown>

                    if (mode === 'replace') {
                        result = values
                    } else {
                        result = jsonPatch(existing, values).result
                        const prevApplied = await ctx.getAppliedState(id)
                        const prevKeys = prevApplied?.details?.['keys']
                        if (Array.isArray(prevKeys)) {
                            const removed = (prevKeys as string[]).filter((k) => !(k in values))
                            result = removeKeys(result, removed)
                        }
                    }
                    atomicWriteJson(SETTINGS_PATH, result)
                }
                if (plan.action !== 'noop' && plan.action !== 'preserve' && plan.action !== 'error') {
                    await ctx.saveAppliedState({
                        id,
                        kind: 'vscode.settings',
                        details: { path: SETTINGS_PATH, mode, keys: Object.keys(values) },
                    })
                }
            },
        }
    }

    private extensionStep(extensionId: string): Step {
        const id = `vscode.extension.${extensionId}`
        return {
            id,
            kind: 'vscode.extension',
            title: `vscode extension ${extensionId}`,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const { stdout } = Bun.spawnSync(['code', '--list-extensions'])
                const installed = new Set(
                    stdout
                        .toString()
                        .split('\n')
                        .map((s) => s.trim())
                        .filter(Boolean),
                )
                if (installed.has(extensionId)) {
                    return applied
                        ? { action: 'noop', message: `${extensionId} already installed`, changed: false }
                        : { action: 'adopt', message: `${extensionId} already installed (adopt)`, changed: false }
                }
                return { action: 'create', message: `will install extension ${extensionId}`, changed: true }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create') {
                    await run(['code', '--install-extension', extensionId])
                }
                if (plan.action !== 'noop' && plan.action !== 'preserve' && plan.action !== 'error') {
                    await ctx.saveAppliedState({ id, kind: 'vscode.extension', details: { extensionId } })
                }
            },
        }
    }
}
