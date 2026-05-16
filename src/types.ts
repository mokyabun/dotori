export type PlanAction = 'noop' | 'create' | 'update' | 'remove' | 'adopt' | 'preserve' | 'error'

export interface PlanResult {
    action: PlanAction
    message: string
    changed: boolean
    data?: unknown
}

export type HookCommand = string | string[] | { command: string[]; description?: string }

export interface StepHooks {
    afterChange?: HookCommand[]
    afterApply?: HookCommand[]
}

export interface Step {
    id: string
    kind: string
    title: string
    hooks?: StepHooks
    plan(ctx: PlanContext): Promise<PlanResult>
    apply(ctx: ApplyContext, plan: PlanResult): Promise<void>
}

export interface StepGroup {
    id: string
    title?: string
    steps: Step[]
    hooks?: StepHooks
}

export type QueueNode = { type: 'step'; step: Step } | { type: 'group'; group: StepGroup }

export interface AppliedState {
    id: string
    kind: string
    details?: Record<string, unknown>
    createdAt: string
    updatedAt: string
}

export interface PlanContext {
    getAppliedState(id: string): Promise<AppliedState | undefined>
}

export interface ApplyContext {
    getAppliedState(id: string): Promise<AppliedState | undefined>
    saveAppliedState(state: Omit<AppliedState, 'createdAt' | 'updatedAt'>): Promise<void>
    deleteAppliedState(id: string): Promise<void>
}
