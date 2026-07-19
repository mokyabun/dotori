import os from 'node:os'
import type { Context } from 'dotori'

export default (ctx: Context) => {
    const home = os.homedir()

    ctx.brew.tap('thusvill/livewallpaper')
    ctx.brew.trustCask('thusvill/livewallpaper/livewallpaper')
    ctx.brew.cask('livewallpaper')

    // yabai + skhd
    ctx.brew.tap('koekeishiya/formulae')
    ctx.brew.install('koekeishiya/formulae/yabai')
    ctx.brew.install('koekeishiya/formulae/skhd')
    ctx.file.symlink('~/.config/yabai', '../dotfiles/yabai')
    ctx.file.symlink('~/.config/skhd', '../dotfiles/skhd')
    ctx.launchd.agent('yabai', {
        ProgramArguments: ['/opt/homebrew/bin/yabai'],
        RunAtLoad: true,
        KeepAlive: true,
    })
    ctx.launchd.agent('skhd', {
        ProgramArguments: ['/opt/homebrew/bin/skhd'],
        RunAtLoad: true,
        KeepAlive: true,
    })

    // Dependencies for Hammerspoon
    ctx.brew.cask('font-jetbrains-mono-nerd-font')
    ctx.brew.install('macmon')

    // Hammerspoon
    ctx.brew.cask('hammerspoon')
    ctx.file.symlink('~/.config/hammerspoon', '../dotfiles/hammerspoon')

    const hostname = process.env.HOSTNAME || os.hostname()
    ctx.macos.defaults('hammerspoon', 'org.hammerspoon.Hammerspoon', {
        MJConfigFile: `${home}/.config/hammerspoon/${hostname}_init.lua`,
    })
    ctx.launchd.agent('hammerspoon', {
        ProgramArguments: ['/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon'],
        RunAtLoad: true,
        KeepAlive: true,
    })

    // Jankeyborder
    ctx.brew.tap('felixkratz/formulae')
    ctx.brew.trustFormula('felixkratz/formulae/borders')
    ctx.brew.install('borders')
    ctx.launchd.agent('jankeyborder', {
        ProgramArguments: [
            '/opt/homebrew/bin/borders',
            'active_color=0xff7287fd',
            'inactive_color=0x00000000',
            'width=7.0',
        ],
        RunAtLoad: true,
        KeepAlive: true,
    })
}
