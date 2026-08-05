import { cac } from 'cac'
import pc from 'picocolors'
import type { Dotori } from './app'
import { printPlan } from './commands/plan'

export interface RunCliOptions {
    name?: string
    version?: string
}

export interface DoctorCheck {
    name: string
    command: string[]
}

export const DEFAULT_DOCTOR_CHECKS: DoctorCheck[] = [
    { name: 'brew', command: ['brew', '--version'] },
    { name: 'code (VSCode)', command: ['code', '--version'] },
    { name: 'plutil', command: ['plutil', '-help'] },
]

function printError(error: unknown): void {
    console.error(pc.red(`Error: ${error instanceof Error ? error.message : String(error)}`))
}

export async function runCli(
    dotori: Dotori,
    argv: string[] = Bun.argv.slice(2),
    options: RunCliOptions = {},
): Promise<void> {
    const name = options.name ?? 'dotori'
    const cli = cac(name)

    cli.usage('[command] [options]').help()
    if (options.version) cli.version(options.version)

    cli.command('plan [groupId]', 'Show what would change').action(async (groupId?: string) => {
        printPlan(await dotori.plan(groupId))
    })

    cli.command('apply [groupId]', 'Apply the configuration').action((groupId?: string) => dotori.apply(groupId))

    cli.command('clean [groupId]', 'Remove resources no longer declared in config').action((groupId?: string) =>
        dotori.clean(groupId),
    )

    cli.command('doctor', 'Check environment health').action(() => {
        for (const { name, command } of DEFAULT_DOCTOR_CHECKS) {
            const { exitCode } = Bun.spawnSync(command)
            console.log(exitCode === 0 ? `${pc.green('ok')} ${name}` : `${pc.red('fail')} ${name}`)
        }
    })

    cli.parse(['bun', name, ...argv], { run: false })

    try {
        await cli.runMatchedCommand()
    } catch (error) {
        printError(error)
        process.exitCode = 1
    }
}
