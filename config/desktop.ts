import type { Context } from '../src/context'

export default (ctx: Context) => {
    // Aerospace
    ctx.brew.tap('nikitabobko/tap')
    ctx.brew.cask('aerospace')
    ctx.file.symlink('~/.config/aerospace', './dotfiles/aerospace')
    ctx.launchd.agent('aerospace', {
        Label: 'com.nikitabobko.aerospace',
        ProgramArguments: [
            '/Applications/Aerospace.app/Contents/MacOS/Aerospace',
            '--config',
            '~/.config/aerospace/config.yaml',
        ],
        RunAtLoad: true,
        KeepAlive: true,
    })

    // Dependencies for Hammerspoon
    ctx.brew.cask('font-jetbrains-mono-nerd-font')
    ctx.brew.install('macmon')

    // Hammerspoon
    ctx.brew.cask('hammerspoon')
    ctx.file.symlink('~/.config/hammerspoon', './dotfiles/hammerspoon')
    ctx.macos.defaults('hammerspoon', 'org.hammerspoon.Hammerspoon', {
        MJConfigFile: '~/.config/hammerspoon/macbook_init.lua',
    })

    // Jankeyborder
    ctx.brew.tap('felixkratz/formulae')
    ctx.brew.install('borders')
    ctx.launchd.agent('jankeyborder', {
        Label: 'com.nikitabobko.jankeyborder',
        ProgramArguments: [
            '/opt/homebrew/bin/borders',
            'active_color=0xffb4befe',
            'inactive_color=0x00000000',
            'width=7.0',
        ],
        RunAtLoad: true,
        KeepAlive: true,
    })
}
