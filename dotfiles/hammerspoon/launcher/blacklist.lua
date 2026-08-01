return {
	-- Bundle IDs are stable even when an app's display name changes.
	bundleIds = {
		-- macOS shell and launcher shortcuts
		"com.apple.launchpad.launcher", -- Launchpad
		"com.apple.exposelauncher", -- Mission Control
		"com.apple.siri.launcher", -- Siri
		"com.apple.backup.launcher", -- Time Machine
		"com.apple.screenshot.launcher", -- Screenshot
		"com.apple.printcenter", -- Print Center

		-- Always-running menu bar utilities
		"org.hammerspoon.Hammerspoon", -- Hammerspoon
		"com.jordanbaird.Ice", -- Ice
		"com.lujjjh.LinearMouse", -- LinearMouse
		"com.thusvill.LiveWallpaper", -- LiveWallpaper
		"com.bitgapp.eqmac", -- eqMac
		"com.unicorn-soft.unicornhttpsformac", -- Unicorn HTTPS
	},

	-- Use the .app filename (without the extension) when a bundle ID is unknown.
	names = {
		-- "Some App",
	},
}
