import type { Context } from '../../src/context'

export default (ctx: Context) => {
    ctx.brew.install('git')

    // Node
    ctx.brew.tap('oven-sh/bun')
    ctx.brew.install('bun')
    ctx.brew.install('node')

    // Python
    ctx.brew.install('uv')

    // Docker
    ctx.brew.cask('orbstack')

    // Terraform, Ansible
    ctx.brew.tap('hashicorp/tap')
    ctx.brew.install('terraform')
    ctx.brew.install('ansible')
}
