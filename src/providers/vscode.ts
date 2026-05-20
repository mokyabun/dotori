import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { z } from 'zod'
import type { Step, PlanContext, ApplyContext, PlanResult, StepHooks } from '../types'
import { StepHooksSchema } from '../types'
import { run } from '../utils/shell'
import { jsonPatch, removeKeys } from '../utils/json'
import { atomicWriteJson } from '../utils/atomic'
import { shouldSave, noopOrAdopt } from '../utils/plan'

type SettingsMode = 'patch' | 'replace'

export const KeybindingSchema = z.object({
    key: z.string(),
    command: z.string(),
    when: z.string().optional(),
    args: z.record(z.string(), z.unknown()).optional(),
})

export const ProfileConfigSchema = z.object({
    location: z.string().optional(),
    settings: z
        .object({
            mode: z.enum(['patch', 'replace']),
            values: z.record(z.string(), z.unknown()),
        })
        .optional(),
    extensions: z.array(z.string()).optional(),
    keybindings: z.array(KeybindingSchema).optional(),
    tasks: z.record(z.string(), z.unknown()).optional(),
    mcp: z.record(z.string(), z.unknown()).optional(),
    languageSnippets: z.record(z.string(), z.record(z.string(), z.unknown())).optional(),
    globalSnippets: z.record(z.string(), z.unknown()).optional(),
    hooks: StepHooksSchema.optional(),
})

export type Keybinding = z.infer<typeof KeybindingSchema>
export type ProfileConfig = z.infer<typeof ProfileConfigSchema>

const VSCODE_USER_DIR = path.join(os.homedir(), 'Library', 'Application Support', 'Code', 'User')
const STORAGE_PATH = path.join(VSCODE_USER_DIR, 'globalStorage', 'storage.json')

function readJsonFile(filePath: string): Record<string, unknown> {
    try {
        return JSON.parse(fs.readFileSync(filePath, 'utf8'))
    } catch {
        return {}
    }
}

function settingsPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'settings.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'settings.json')
}

function keybindingsPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'keybindings.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'keybindings.json')
}

function tasksPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'tasks.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'tasks.json')
}

function mcpPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'mcp.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'mcp.json')
}

function snippetsDir(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'snippets')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'snippets')
}

export class VscodeProvider {
    constructor(private readonly push: (step: Step) => void) { }

    profile(name: string, config: ProfileConfig): void {
        const {
            location = name,
            settings,
            extensions,
            keybindings,
            tasks,
            mcp,
            languageSnippets,
            globalSnippets,
            hooks,
        } = ProfileConfigSchema.parse(config)

        if (name !== 'default') {
            this.push(this.profileStep(name, location, hooks))
        }
        if (settings) {
            this.push(this.settingsStep(name, settings.mode, settings.values, hooks))
        }
        for (const ext of extensions ?? []) {
            this.push(this.extensionStep(name, ext))
        }
        if (keybindings?.length) {
            this.push(this.keybindingsStep(name, keybindings, hooks))
        }
        if (tasks && Object.keys(tasks).length > 0) {
            this.push(this.tasksStep(name, tasks, hooks))
        }
        if (mcp && Object.keys(mcp).length > 0) {
            this.push(this.mcpStep(name, mcp, hooks))
        }
        for (const [language, snippet] of Object.entries(languageSnippets ?? {})) {
            this.push(this.languageSnippetStep(name, language, snippet, hooks))
        }
        if (globalSnippets && Object.keys(globalSnippets).length > 0) {
            this.push(this.globalSnippetsStep(name, globalSnippets, hooks))
        }
    }

    /**
     * Shared factory for steps that simply compare a JSON file to a desired value
     * and overwrite it when they differ.
     */
    private makeJsonEqualStep(params: {
        id: string
        kind: string
        title: string
        filePath: string
        desired: unknown
        details: Record<string, unknown>
        hooks?: StepHooks
        setup?: () => void
    }): Step {
        const { id, kind, title, filePath, desired, details, hooks, setup } = params
        return {
            id,
            kind,
            title,
            hooks,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const existing = readJsonFile(filePath)
                if (JSON.stringify(existing) === JSON.stringify(desired)) {
                    return noopOrAdopt(applied, `${title} already correct`)
                }
                return { action: 'update', message: `will update ${title}`, changed: true }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create' || plan.action === 'update') {
                    setup?.()
                    atomicWriteJson(filePath, desired)
                }
                if (shouldSave(plan.action)) {
                    await ctx.saveAppliedState({ id, kind, details })
                }
            },
        }
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
                if (existing?.location === location) return noopOrAdopt(applied, `profile ${name} already registered`)
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
                    if (idx >= 0) profiles[idx] = entry
                    else profiles.push(entry)
                    atomicWriteJson(STORAGE_PATH, { ...storage, userDataProfiles: profiles })
                }
                if (shouldSave(plan.action)) {
                    await ctx.saveAppliedState({ id, kind: 'vscode.profile', details: { name, location } })
                }
            },
        }
    }

    private settingsStep(name: string, mode: SettingsMode, values: Record<string, unknown>, hooks?: StepHooks): Step {
        const filePath = settingsPath(name)
        const id = `vscode.${name}.settings`
        return {
            id,
            kind: 'vscode.settings',
            title: `vscode ${name} settings (${mode})`,
            hooks,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                const existing = readJsonFile(filePath)
                if (mode === 'replace') {
                    if (JSON.stringify(existing) === JSON.stringify(values)) {
                        return noopOrAdopt(applied, `vscode ${name} settings already correct`)
                    }
                    return { action: 'update', message: `will replace vscode ${name} settings`, changed: true }
                }
                const { changedKeys } = jsonPatch(existing, values)
                if (changedKeys.length === 0) return noopOrAdopt(applied, `vscode ${name} settings already correct`)
                return {
                    action: 'update',
                    message: `will patch vscode ${name} settings (keys: ${changedKeys.join(', ')})`,
                    changed: true,
                }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create' || plan.action === 'update') {
                    const existing = readJsonFile(filePath)
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
                    atomicWriteJson(filePath, result)
                }
                if (shouldSave(plan.action)) {
                    await ctx.saveAppliedState({
                        id,
                        kind: 'vscode.settings',
                        details: { path: filePath, mode, keys: Object.keys(values) },
                    })
                }
            },
        }
    }

    private extensionStep(profileName: string, extensionId: string): Step {
        const id = `vscode.${profileName}.extension.${extensionId}`
        const profileArgs = profileName === 'default' ? [] : ['--profile', profileName]
        const extensionsDir = path.join(os.homedir(), '.vscode', 'extensions')

        function isProperlyInstalled(): boolean {
            const result = Bun.spawnSync(['code', ...profileArgs, '--list-extensions'])
            if (result.exitCode !== 0) return false
            const listed = new Set(
                result.stdout
                    .toString()
                    .split('\n')
                    .map((s) => s.trim().toLowerCase())
                    .filter(Boolean),
            )
            if (!listed.has(extensionId.toLowerCase())) return false

            // Verify the extension directory actually exists on disk.
            // All extension files live in extensionsDir regardless of which profile they
            // belong to — directories are named like `<publisher>.<name>-<version>`.
            // This avoids parsing extensions.json, whose format differs between the global
            // registry and per-profile registries.
            try {
                const prefix = extensionId.toLowerCase() + '-'
                return fs
                    .readdirSync(extensionsDir)
                    .some(
                        (dir) =>
                            dir.toLowerCase().startsWith(prefix) &&
                            fs.existsSync(path.join(extensionsDir, dir, 'package.json')),
                    )
            } catch {
                return false
            }
        }

        return {
            id,
            kind: 'vscode.extension',
            title: `vscode ${profileName} extension ${extensionId}`,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                if (isProperlyInstalled())
                    return noopOrAdopt(applied, `${extensionId} already installed in ${profileName}`)
                return { action: 'create', message: `will install ${extensionId} in ${profileName}`, changed: true }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create') {
                    await run(['code', ...profileArgs, '--install-extension', extensionId])
                }
                if (shouldSave(plan.action)) {
                    await ctx.saveAppliedState({ id, kind: 'vscode.extension', details: { extensionId, profileName } })
                }
            },
        }
    }

    private keybindingsStep(name: string, keybindings: Keybinding[], hooks?: StepHooks): Step {
        const filePath = keybindingsPath(name)
        const id = `vscode.${name}.keybindings`
        const filtered = keybindings.map(({ key, command, when, args }) => {
            const entry: Record<string, unknown> = { key, command }
            if (when != null) entry.when = when
            if (args != null) entry.args = args
            return entry
        })
        return this.makeJsonEqualStep({
            id,
            kind: 'vscode.keybindings',
            title: `vscode ${name} keybindings`,
            filePath,
            desired: filtered,
            details: { path: filePath },
            hooks,
        })
    }

    private tasksStep(name: string, tasks: Record<string, unknown>, hooks?: StepHooks): Step {
        return this.makeJsonEqualStep({
            id: `vscode.${name}.tasks`,
            kind: 'vscode.tasks',
            title: `vscode ${name} tasks`,
            filePath: tasksPath(name),
            desired: tasks,
            details: { path: tasksPath(name) },
            hooks,
        })
    }

    private mcpStep(name: string, mcp: Record<string, unknown>, hooks?: StepHooks): Step {
        return this.makeJsonEqualStep({
            id: `vscode.${name}.mcp`,
            kind: 'vscode.mcp',
            title: `vscode ${name} mcp`,
            filePath: mcpPath(name),
            desired: mcp,
            details: { path: mcpPath(name) },
            hooks,
        })
    }

    private languageSnippetStep(
        profileName: string,
        language: string,
        snippet: Record<string, unknown>,
        hooks?: StepHooks,
    ): Step {
        const filePath = path.join(snippetsDir(profileName), `${language}.json`)
        return this.makeJsonEqualStep({
            id: `vscode.${profileName}.snippets.${language}`,
            kind: 'vscode.snippet',
            title: `vscode ${profileName} ${language} snippets`,
            filePath,
            desired: snippet,
            details: { path: filePath, language },
            hooks,
            setup: () => fs.mkdirSync(path.dirname(filePath), { recursive: true }),
        })
    }

    private globalSnippetsStep(profileName: string, snippets: Record<string, unknown>, hooks?: StepHooks): Step {
        const filePath = path.join(snippetsDir(profileName), 'global.code-snippets')
        return this.makeJsonEqualStep({
            id: `vscode.${profileName}.snippets.global`,
            kind: 'vscode.snippet',
            title: `vscode ${profileName} global snippets`,
            filePath,
            desired: snippets,
            details: { path: filePath },
            hooks,
            setup: () => fs.mkdirSync(path.dirname(filePath), { recursive: true }),
        })
    }
}
