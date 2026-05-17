local colors = require("lib.colors")

return {
	hotkey = { mods = { "cmd" }, key = "space" },
	scanDirs = {
		"/Applications",
		"/System/Applications",
		os.getenv("HOME") .. "/Applications",
	},
	dbPath = hs.configdir .. "/data/launcher.db",
	chooser = { width = 36, rows = 10, fgColor = colors.text, subTextColor = colors.subtext0 },
}
