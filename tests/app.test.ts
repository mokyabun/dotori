import { describe, expect, test } from 'bun:test'
import { createDotori, defineConfig } from '../src'

describe('createDotori', () => {
    test('evaluates a procedural config once and keeps declaration order', async () => {
        let evaluations = 0
        const config = defineConfig((ctx) => {
            evaluations += 1
            ctx.brew.install('ripgrep')
            ctx.group('developer/shell', (group) => {
                group.brew.install('fzf')
            })
        })

        const dotori = await createDotori({ config, configCwd: '/tmp/dotori-config' })

        expect(evaluations).toBe(1)
        expect(dotori.queue).toHaveLength(2)
        expect(dotori.queue[0]?.type).toBe('step')
        expect(dotori.queue[1]?.type).toBe('group')
        expect(dotori.queue[1]?.type === 'group' ? dotori.queue[1].group.id : undefined).toBe('developer/shell')
    })

    test('exposes plan through the library instance', async () => {
        const config = defineConfig((ctx) => {
            ctx.group('empty', () => {})
        })
        const dotori = await createDotori({ config, configCwd: '/tmp/dotori-config' })

        const output = await dotori.plan('empty')

        expect(output).toHaveLength(1)
        expect(output[0]?.type).toBe('group')
    })
})
