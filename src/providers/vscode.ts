import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import type { Step, PlanContext, ApplyContext, PlanResult, StepHooks } from '../types'
import { run } from '../utils/shell'
import { jsonPatch, removeKeys } from '../utils/json'
import { atomicWriteJson } from '../utils/atomic'

type SettingsMode = 'patch' | 'replace'

const VSCODE_USER_DIR = path.join(os.homedir(), 'Library', 'Application Support', 'Code', 'User')
const SETTINGS_PATH = path.join(VSCODE_USER_DIR, 'settings.json')
const STORAGE_PATH = path.join(VSCODE_USER_DIR, 'globalStorage', 'storage.json')

function readJsonFile(filePath: string): Record<string, unknown> {
    try {
        return JSON.parse(fs.readFileSync(filePath, 'utf8'))
    } catch {
        return {}
    }
}

export class VscodeProfileBuilder {
    constructor(
        private readonly name: string,
        private readonly location: string,
        private readonly push: (step: Step) => void,
    ) { }

    settings(
        suffix: string,
        options: { mode: SettingsMode; values: Record<string, unknown>; hooks?: StepHooks },
    ): void {
        this.push(this.settingsStep(suffix, options.mode, options.values, options.hooks))
    }

    extension(extensionId: string): void {
        this.push(this.extensionStep(extensionId))
    }

    private settingsStep(
        suffix: string,
        mode: SettingsMode,
        values: Record<string, unknown>,
        hooks?: StepHooks,
    ): Step {
        const { name: profileName, location: profileLocation } = this
        const settingsPath = path.join(VSCODE_USER_DIR, 'profiles', profileLocation, 'settings.json')
        const id = `vscode.profile.${profileName}.settings.${suffix}`

        return {
            id,
            kind: 'vscode.profile.settings',
            title: `vscode profile ${profileName} settings ${mode} (${suffix})`,
            hooks,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const existing = readJsonFile(settingsPath)

                if (mode === 'replace') {
                    if (JSON.stringify(existing) === JSON.stringify(values)) {
                        return applied
                            ? { action: 'noop', message: 'vscode profile settings already correct', changed: false }
                            : { action: 'adopt', message: 'vscode profile settings already correct (adopt)', changed: false }
                    }
                    return { action: 'update', message: `will replace vscode profile ${profileName} settings`, changed: true }
                }

                const { changedKeys } = jsonPatch(existing, values)
                if (changedKeys.length === 0) {
                    return applied
                        ? { action: 'noop', message: 'vscode profile settings already correct', changed: false }
                        : { action: 'adopt', message: 'vscode profile settings already correct (adopt)', changed: false }
                }
                return {
                    action: 'update',
                    message: `will patch vscode profile ${profileName} settings (keys: ${changedKeys.join(', ')})`,
                    changed: true,
                }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create' || plan.action === 'update') {
                    const existing = readJsonFile(settingsPath)
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
                    atomicWriteJson(settingsPath, result)
                }
                if (plan.action !== 'noop' && plan.action !== 'preserve' && plan.action !== 'error') {
                    await ctx.saveAppliedState({
                        id,
                        kind: 'vscode.profile.settings',
                        details: { path: settingsPath, mode, keys: Object.keys(values) },
                    })
                }
            },
        }
    }

    private extensionStep(extensionId: string): Step {
        const { name: profileName } = this
        const id = `vscode.profile.${profileName}.extension.${extensionId}`
        return {
            id,
            kind: 'vscode.profile.extension',
            title: `vscode profile ${profileName} extension ${extensionId}`,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const { stdout } = Bun.spawnSync(['code', '--profile', profileName, '--list-extensions'])
                const installed = new Set(
                    stdout
                        .toString()
                        .split('\n')
                        .map((s) => s.trim())
                        .filter(Boolean),
                )
                if (installed.has(extensionId)) {
                    return applied
                        ? { action: 'noop', message: `${extensionId} already installed in profile ${profileName}`, changed: false }
                        : { action: 'adopt', message: `${extensionId} already installed in profile ${profileName} (adopt)`, changed: false }
                }
                return { action: 'create', message: `will install extension ${extensionId} in profile ${profileName}`, changed: true }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create') {
                    await run(['code', '--profile', profileName, '--install-extension', extensionId])
                }
                if (plan.action !== 'noop' && plan.action !== 'preserve' && plan.action !== 'error') {
                    await ctx.saveAppliedState({ id, kind: 'vscode.profile.extension', details: { extensionId, profileName } })
                }
            },
        }
    }
}

export class VscodeProvider {
    constructor(private readonly push: (step: Step) => void) { }

    settings(
        suffix: string,
        options: { mode: SettingsMode; values: Record<string, unknown>; hooks?: StepHooks },
    ): void {
        this.push(this.settingsStep(suffix, options.mode, options.values, options.hooks))
    }

    extension(extensionId: string): void {
        this.push(this.extensionStep(extensionId))
    }

    profile(
        name: string,
        optionsOrFn: { location?: string; hooks?: StepHooks } | ((p: VscodeProfileBuilder) => void),
        fn?: (p: VscodeProfileBuilder) => void,
    ): void {
        let options: { location?: string; hooks?: StepHooks } = {}
        let builderFn: (p: VscodeProfileBuilder) => void

        if (typeof optionsOrFn === 'function') {
            builderFn = optionsOrFn
        } else {
            options = optionsOrFn
            builderFn = fn!
        }

        const location = options.location ?? name
        this.push(this.profileStep(name, location, options.hooks))
        const builder = new VscodeProfileBuilder(name, location, this.push)
        builderFn(builder)
    }

    private profileStep(name: string, location: string, hooks?: StepHooks): Step {
        const id = `vscode.profile.${name}`
        return {
            id,
            kind: 'vscode.profile',
            title: `vscode profile ${name}`,
            hooks,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const storage = readJsonFile(STORAGE_PATH)
                const profiles = (storage['userDataProfiles'] as Array<{ name: string; location: string }>) ?? []
                const existing = profiles.find((p) => p.name === name)

                if (existing?.location === location) {
                    return applied
                        ? { action: 'noop', message: `profile ${name} already registered`, changed: false }
                        : { action: 'adopt', message: `profile ${name} already registered (adopt)`, changed: false }
                }
                return {
                    action: existing ? 'update' : 'create',
                    message: `will ${existing ? 'update' : 'create'} profile ${name}`,
                    changed: true,
                }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create' || plan.action === 'update') {
                    const storage = readJsonFile(STORAGE_PATH)
                    const profiles = (storage['userDataProfiles'] as Array<{ name: string; location: string }>) ?? []
                    const idx = profiles.findIndex((p) => p.name === name)
                    const entry = { name, location }
                    if (idx >= 0) {
                        profiles[idx] = entry
                    } else {
                        profiles.push(entry)
                    }
                    atomicWriteJson(STORAGE_PATH, { ...storage, userDataProfiles: profiles })
                }
                if (plan.action !== 'noop' && plan.action !== 'preserve' && plan.action !== 'error') {
                    await ctx.saveAppliedState({ id, kind: 'vscode.profile', details: { name, location } })
                }
            },
        }
    }

    private settingsStep(suffix: string, mode: SettingsMode, values: Record<string, unknown>, hooks?: StepHooks): Step {
        const id = `vscode.settings.${suffix}`

        return {
            id,
            kind: 'vscode.settings',
            title: `vscode settings ${mode} (${suffix})`,
            hooks,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const existing = readJsonFile(SETTINGS_PATH)

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
                    const existing = readJsonFile(SETTINGS_PATH)
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
