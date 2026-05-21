import os from 'node:os'
import * as db from './db'
import { BrewProvider } from './providers/brew'
import { FileProvider } from './providers/file'
import { LaunchdProvider } from './providers/launchd'
import { MacosProvider } from './providers/macos'
import { VscodeProvider } from './providers/vscode'
import type { ApplyContext, PlanContext, QueueNode, Step, StepGroup, StepHooks } from './types'

export type Queue = QueueNode[]

export interface Context {
    brew: BrewProvider
    file: FileProvider
    vscode: VscodeProvider
    macos: MacosProvider
    launchd: LaunchdProvider
    env: { username: string }
    group(id: string, fn: (g: Context) => void, options?: { hooks?: StepHooks }): void
}

export function makePlanContext(): PlanContext {
    return {
        getAppliedState(id) {
            return Promise.resolve(db.getAppliedState(id))
        },
    }
}

export function makeApplyContext(): ApplyContext {
    return {
        getAppliedState(id) {
            return Promise.resolve(db.getAppliedState(id))
        },
        saveAppliedState(state) {
            db.saveAppliedState(state)
            return Promise.resolve()
        },
        deleteAppliedState(id) {
            db.deleteAppliedState(id)
            return Promise.resolve()
        },
    }
}

export function createContext(queue: Queue, configCwd: string): Context {
    function buildCtx(push: (step: Step) => void): Context {
        return {
            brew: new BrewProvider(push),
            file: new FileProvider(push, configCwd),
            vscode: new VscodeProvider(push),
            macos: new MacosProvider(push),
            launchd: new LaunchdProvider(push),
            env: { username: os.userInfo().username },
            group(id, fn, options) {
                const steps: Step[] = []
                fn(buildCtx((step) => steps.push(step)))
                const group: StepGroup = { id, steps, hooks: options?.hooks }
                queue.push({ type: 'group', group })
            },
        }
    }

    return buildCtx((step) => queue.push({ type: 'step', step }))
}
