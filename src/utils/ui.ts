import chalk from 'chalk'
import type { PlanAction } from '../types'

const ACTION_COLORS: Record<PlanAction, (s: string) => string> = {
    noop: chalk.gray,
    adopt: chalk.blue,
    create: chalk.green,
    update: chalk.yellow,
    remove: chalk.red,
    preserve: chalk.magenta,
    error: (s) => chalk.bgRed.white(s),
}

export function colorAction(action: PlanAction): string {
    return ACTION_COLORS[action](action)
}

export function printGroupHeader(id: string): void {
    console.log(chalk.bold.cyan(`\n[group: ${id}]`))
}
