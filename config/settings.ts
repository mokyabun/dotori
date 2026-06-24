import type { Context } from 'dotori'

const finderListColumns = [
    { identifier: 'name', visible: true, ascending: true, width: 300 },
    { identifier: 'dateModified', visible: true, ascending: false, width: 181 },
    { identifier: 'dateCreated', visible: false, ascending: false, width: 181 },
    { identifier: 'size', visible: true, ascending: false, width: 97 },
    { identifier: 'kind', visible: true, ascending: true, width: 115 },
    { identifier: 'label', visible: false, ascending: true, width: 100 },
    { identifier: 'version', visible: false, ascending: true, width: 75 },
    { identifier: 'comments', visible: false, ascending: true, width: 300 },
    { identifier: 'dateLastOpened', visible: false, ascending: false, width: 200 },
    { identifier: 'shareOwner', visible: false, ascending: false, width: 200 },
    { identifier: 'shareLastEditor', visible: false, ascending: false, width: 200 },
]

const finderListViewSettings = {
    calculateAllSizes: false,
    columns: finderListColumns,
    iconSize: 16,
    showIconPreview: true,
    sortColumn: 'dateModified',
    textSize: 13,
    useRelativeDates: true,
    viewOptionsVersion: 0,
}

const finderLegacyListViewSettings = {
    ...finderListViewSettings,
    columns: Object.fromEntries(finderListColumns.map((column, index) => [column.identifier, { ...column, index }])),
}

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
            AppleShowAllFiles: true,
            FXDefaultSearchScope: 'SCcf',
            FXEnableExtensionChangeWarning: false,
            FXPreferredViewStyle: 'Nlsv',
            FK_DefaultListViewSettings: finderListViewSettings,
            ShowPathbar: true,
            ShowStatusBar: true,
            FK_StandardViewSettings: {
                ExtendedListViewSettingsV2: finderListViewSettings,
                ListViewSettings: finderLegacyListViewSettings,
                SettingsType: 'FK_StandardViewSettings',
            },
            StandardViewSettings: {
                ExtendedListViewSettingsV2: finderListViewSettings,
                ListViewSettings: finderLegacyListViewSettings,
                SettingsType: 'StandardViewSettings',
            },
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
                '61': { enabled: false },

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
