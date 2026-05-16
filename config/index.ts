import type { Context } from '../src/context'
import settings from './settings'
import desktop from './desktop'
import development from './development'
import vscode from './vscode'

export default (ctx: Context) => {
    ctx.brew.install('git')
    ctx.brew.install('mas')
    ctx.brew.cask('vesktop')
    ctx.brew.cask('parsec')

    ctx.group('settings', (g) => settings(g), {
        hooks: {
            afterChange: [
                [
                    'sudo',
                    '-u',
                    // ctx.env.username is available if needed
                    ctx.env.username,
                    '/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings',
                    '-u',
                ],
            ],
        },
    })
    ctx.group('desktop', (g) => desktop(g))
    ctx.group('development', (g) => development(g))
    ctx.group('vscode', (g) => vscode(g))
}
