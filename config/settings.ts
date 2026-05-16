import type { Context } from '../src/context'

export default (ctx: Context) => {
    ctx.macos.plist('dock', 'com.apple.dock', {
        mode: 'patch',
        values: {
            autohide: true,
            'show-recents': false,
            'static-only': true,
        },
        afterChange: [['killall', 'Dock']],
    })

    ctx.macos.plist('finder', 'com.apple.finder', {
        mode: 'patch',
        values: {
            ShowPathbar: true,
            AppleShowAllFiles: true,
        },
        afterChange: [['killall', 'Finder']],
    })

    ctx.macos.plist('screenshot', 'com.apple.screencapture', {
        mode: 'patch',
        values: {
            'disable-shadow': true,
        },
    })

    ctx.macos.plist('trackpad', 'com.apple.AppleMultitouchTrackpad', {
        mode: 'patch',
        values: {
            TrackpadThreeFingerDrag: true,
        },
    })

    ctx.macos.plist('window-manager', 'com.apple.WindowManager', {
        mode: 'patch',
        values: {
            EnableStandardClickToShowDesktop: false,
        },
        afterChange: [['killall', 'WindowManager']],
    })

    ctx.macos.plist('hotkey', 'com.apple.symbolichotkeys', {
        mode: 'patch',
        values: {
            AppleSymbolicHotKeys: {
                // 이전 입력 소스 선택
                '60': {
                    enabled: true,
                    value: {
                        parameters: [65535, 80, 0],
                        type: 'standard',
                    },
                },
                // 입력 메뉴에서 다음 소스 선택
                "61": { enabled: false },

                // Spotlight 검색창 열기
                '64': {
                    enabled: false,
                    value: {
                        // change to random value to avoid conflict with other shortcuts
                        parameters: [59, 41, 1179648],
                        type: 'standard',
                    },
                },
            },
        },
    })
}
