import { runApply } from './commands/apply'
import { runClean } from './commands/clean'
import { type PlanOutput, runPlan } from './commands/plan'
import type { DotoriProviderFactory, Queue } from './context'
import { createQueue, type DotoriConfig } from './runner'
import type { DotoriEnv } from './types'

export interface DotoriOptions {
    config: DotoriConfig
    configCwd: string
    env?: Partial<DotoriEnv>
    providers?: DotoriProviderFactory[]
}

export interface Dotori {
    readonly configCwd: string
    readonly queue: Queue
    plan(groupId?: string): Promise<PlanOutput[]>
    apply(groupId?: string): Promise<void>
    clean(groupId?: string): Promise<void>
}

/**
 * Evaluate a procedural config once and return an executable dotori instance.
 * The resulting queue is reused by plan, apply, and clean.
 */
export async function createDotori(options: DotoriOptions): Promise<Dotori> {
    const queue = await createQueue(options.config, {
        configCwd: options.configCwd,
        env: options.env,
        providers: options.providers,
    })

    return {
        configCwd: options.configCwd,
        queue,
        plan(groupId) {
            return runPlan(queue, groupId)
        },
        apply(groupId) {
            return runApply(queue, groupId)
        },
        clean(groupId) {
            return runClean(queue, groupId)
        },
    }
}
