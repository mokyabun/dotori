import { type Context, defineConfig } from 'dotori'
import desktop from './desktop'
import developer from './developer'
import settings from './settings'

export default defineConfig((ctx: Context) => {
    ctx.brew.install('mas')
    ctx.brew.cask('vesktop')
    ctx.brew.cask('parsec')
    ctx.brew.cask('brave-browser')
    ctx.brew.cask('linearmouse')
    ctx.brew.cask('jordanbaird-ice')

    developer(ctx)

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
})
