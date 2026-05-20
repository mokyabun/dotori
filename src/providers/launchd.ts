import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import type { Step, PlanContext, ApplyContext, PlanResult, StepHooks } from '../types'
import { atomicWriteFile } from '../utils/atomic'
import { run, runSafe } from '../utils/shell'
import { shouldSave, noopOrAdopt } from '../utils/plan'

type LaunchAgentConfig = Record<string, unknown>

const LAUNCH_AGENTS_DIR = path.join(os.homedir(), 'Library', 'LaunchAgents')

function buildPlistXml(obj: LaunchAgentConfig): string {
    const lines: string[] = [
        `<?xml version="1.0" encoding="UTF-8"?>`,
        `<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">`,
        `<plist version="1.0">`,
    ]

    function writeValue(val: unknown, indent: string): void {
        if (typeof val === 'string') {
            lines.push(`${indent}<string>${val}</string>`)
        } else if (typeof val === 'number') {
            lines.push(Number.isInteger(val) ? `${indent}<integer>${val}</integer>` : `${indent}<real>${val}</real>`)
        } else if (typeof val === 'boolean') {
            lines.push(`${indent}<${val ? 'true' : 'false'}/>`)
        } else if (Array.isArray(val)) {
            lines.push(`${indent}<array>`)
            for (const item of val) writeValue(item, `${indent}\t`)
            lines.push(`${indent}</array>`)
        } else if (val !== null && typeof val === 'object') {
            lines.push(`${indent}<dict>`)
            for (const [k, v] of Object.entries(val as Record<string, unknown>)) {
                lines.push(`${indent}\t<key>${k}</key>`)
                writeValue(v, `${indent}\t`)
            }
            lines.push(`${indent}</dict>`)
        }
    }

    writeValue(obj, '')
    lines.push(`</plist>`)
    return lines.join('\n') + '\n'
}

export class LaunchdProvider {
    constructor(private readonly push: (step: Step) => void) { }

    agent(label: string, config: LaunchAgentConfig, hooks?: StepHooks): void {
        this.push(this.agentStep(label, config, hooks))
    }

    private agentStep(label: string, config: LaunchAgentConfig, hooks?: StepHooks): Step {
        const id = `launchd.agent.${label}`
        const plistPath = path.join(LAUNCH_AGENTS_DIR, `${label}.plist`)
        const desiredContent = buildPlistXml({ Label: label, ...config })

        return {
            id,
            kind: 'launchd.agent',
            title: `launchd agent ${label}`,
            hooks,
            async plan(ctx: PlanContext): Promise<PlanResult> {
                const applied = await ctx.getAppliedState(id)
                let existing = ''
                try {
                    existing = fs.readFileSync(plistPath, 'utf8')
                } catch { }

                if (existing === desiredContent) return noopOrAdopt(applied, `launchd agent ${label} already correct`)
                return existing
                    ? { action: 'update', message: `will update launchd agent ${label}`, changed: true }
                    : { action: 'create', message: `will create launchd agent ${label}`, changed: true }
            },
            async apply(ctx: ApplyContext, plan: PlanResult): Promise<void> {
                if (plan.action === 'create' || plan.action === 'update') {
                    const uid = os.userInfo().uid
                    const target = `gui/${uid}`
                    fs.mkdirSync(path.dirname(plistPath), { recursive: true })
                    if (plan.action === 'update') {
                        runSafe(['launchctl', 'bootout', target, plistPath])
                    }
                    atomicWriteFile(plistPath, desiredContent)
                    await run(['launchctl', 'bootstrap', target, plistPath])
                }
                if (shouldSave(plan.action)) {
                    await ctx.saveAppliedState({ id, kind: 'launchd.agent', details: { label, path: plistPath } })
                }
            },
        }
    }
}
