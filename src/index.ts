#!/usr/bin/env bun
import { Command } from 'commander'
import { runApply } from './commands/apply'
import { runClean } from './commands/clean'
import { printPlan, runPlan } from './commands/plan'
import { loadConfig } from './runner'

const program = new Command()

program.name('doto').description('Declarative macOS environment manager').version('0.1.0')

program
    .command('plan [groupId]')
    .description('Show what would change')
    .option('-c, --config <path>', 'Config file path', 'config')
    .action(async (groupId: string | undefined, opts: { config: string }) => {
        try {
            const queue = await loadConfig(opts.config)
            printPlan(await runPlan(queue, groupId))
        } catch (e) {
            console.error(`Error: ${e}`)
            process.exit(1)
        }
    })

program
    .command('apply [groupId]')
    .description('Apply the configuration')
    .option('-c, --config <path>', 'Config file path', 'config')
    .action(async (groupId: string | undefined, opts: { config: string }) => {
        try {
            const queue = await loadConfig(opts.config)
            await runApply(queue, groupId)
        } catch (e) {
            console.error(`Error: ${e}`)
            process.exit(1)
        }
    })

program
    .command('clean [groupId]')
    .description('Remove resources no longer declared in config')
    .option('-c, --config <path>', 'Config file path', 'config')
    .action(async (groupId: string | undefined, opts: { config: string }) => {
        try {
            const queue = await loadConfig(opts.config)
            await runClean(queue, groupId)
        } catch (e) {
            console.error(`Error: ${e}`)
            process.exit(1)
        }
    })

program
    .command('doctor')
    .description('Check environment health')
    .action(() => {
        const checks = [
            { name: 'brew', cmd: ['brew', '--version'] },
            { name: 'code (VSCode)', cmd: ['code', '--version'] },
            { name: 'plutil', cmd: ['plutil', '-help'] },
        ]
        for (const { name, cmd } of checks) {
            const { exitCode } = Bun.spawnSync(cmd)
            console.log(exitCode === 0 ? `✓ ${name}` : `✗ ${name} — not found or failed`)
        }
    })

program.parse()
