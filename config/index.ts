import { type Context, defineConfig } from 'dotori'
import desktop from './desktop'
import developer from './developer'
import qol from './qol'
import security from './security'
import settings from './settings'

export default defineConfig((ctx: Context) => {
    ctx.brew.install('mas')

    developer(ctx)

    ctx.group('qol', (g) => qol(g))
    ctx.group('desktop', (g) => desktop(g))

    ctx.group('settings', (g) => settings(g), {
        hooks: {
            afterChange: [
                ['killall', 'cfprefsd'],
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

    ctx.group('security', (g) => security(g))
})
