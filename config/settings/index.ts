import type { Context } from 'dotori'
import desktopAndDock from './desktop-and-dock'
import finder from './finder'
import keyboard from './keyboard'
import menuBar from './menu-bar'
import screenshots from './screenshots'
import spotlight from './spotlight'
import trackpad from './trackpad'

export default (ctx: Context) => {
    desktopAndDock(ctx)
    finder(ctx)
    screenshots(ctx)
    trackpad(ctx)
    keyboard(ctx)
    spotlight(ctx)
    menuBar(ctx)
}
