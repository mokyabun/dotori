import type { Context } from 'dotori'
import { BASE_SETTINGS } from './vscode'

export default (ctx: Context) => {
    ctx.brew.cask('antigravity-ide')

    ctx.file.json('~/Library/Application Support/Antigravity IDE/User/settings.json', {
        mode: 'patch',
        values: {
            ...BASE_SETTINGS,
            'workbench.iconTheme': 'vs-seti',
            'telemetry.feedback.enabled': false,
            'telemetry.telemetryLevel': 'off',
        },
    })
}
