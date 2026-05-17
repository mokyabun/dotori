local colors = require("lib.colors")

return {
	hotkey = { mods = { "option" }, key = "space" },
	dbPath = hs.configdir .. "/data/clipboard.db",
	maxItems = 500,
	pollInterval = 1,
	chooser = { width = 50, rows = 10, fgColor = colors.text, subTextColor = colors.subtext0 },
}
