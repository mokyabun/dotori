import type { Context } from 'dotori'

const fnGlobeToLeftControlMapping = JSON.stringify({
    UserKeyMapping: [
        {
            // Fn/Globe key.
            HIDKeyboardModifierMappingSrc: 0xff00000003,

            // Left Control key.
            HIDKeyboardModifierMappingDst: 0x7000000e0,
        },
    ],
})

export default (ctx: Context) => {
    ctx.macos.plist('macbook.trackpad', 'com.apple.AppleMultitouchTrackpad', {
        mode: 'patch',
        values: {
            // MacBook only override: Trackpad > Point & Click > Tap to click
            Clicking: 1,
        },
    })

    ctx.macos.plist('macbook.trackpad.global', 'NSGlobalDomain', {
        mode: 'patch',
        values: {
            // MacBook only override: keep tap-to-click behavior available to apps that read the global tap setting.
            'com.apple.mouse.tapBehavior': 1,
        },
    })

    ctx.launchd.agent('macbook-fn-globe-to-control', {
        // MacBook only override: Keyboard > Keyboard Shortcuts > Modifier Keys > Globe key -> Control.
        // Apple exposes this remap in System Settings; hidutil makes the same remap reproducible at login.
        ProgramArguments: ['/usr/bin/hidutil', 'property', '--set', fnGlobeToLeftControlMapping],
        RunAtLoad: true,
        ProcessType: 'Background',
    })
}
