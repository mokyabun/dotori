local colors = require("lib.colors")
local palette = colors.mocha

return {
	-- Layout
	BAR_W = 48,
	MARGIN_X = 0,
	MARGIN_Y = 15,
	PAD = 8,
	ITEM_H = 28,
	ITEM_GAP = 2,
	SECTION_GAP = 6,
	DIV_H = 1,
	RADIUS = 2,

	-- Typography
	FONT = "JetBrainsMono Nerd Font",
	WS_SIZE = 12,
	ICON_SIZE = 12,
	TIME_SIZE = 13,
	DATE_SIZE = 11,
	DAY_SIZE = 10,
	POWER_SIZE = 10,
	CAFFEINE_SIZE = 10,

	-- Colors
	BG = colors.withAlpha(palette.mantle, 0.96),
	ACTIVE_BG = palette.surface1,
	DIV = colors.withAlpha(palette.surface0, 0.6),
	TEXT = palette.text,
	MUTED = palette.overlay2,
	DIM = palette.overlay1,
	GOOD = palette.green,
	WARN = palette.yellow,
}
