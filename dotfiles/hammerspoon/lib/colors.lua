-- Catppuccin Latte official color palette
-- https://catppuccin.com/palette
-- All values are normalized 0–1 floats (hex component / 255).

local function rgb(r, g, b)
	return { red = r / 255, green = g / 255, blue = b / 255, alpha = 1 }
end

local M = {
	rosewater = rgb(220, 138, 120),
	flamingo = rgb(221, 120, 120),
	pink = rgb(234, 118, 203),
	mauve = rgb(136, 57, 239),
	red = rgb(210, 15, 57),
	maroon = rgb(230, 69, 83),
	peach = rgb(254, 100, 11),
	yellow = rgb(223, 142, 29),
	green = rgb(64, 160, 43),
	teal = rgb(23, 146, 153),
	sky = rgb(4, 165, 229),
	sapphire = rgb(32, 159, 181),
	blue = rgb(30, 102, 245),
	lavender = rgb(114, 135, 253),
	text = rgb(76, 79, 105),
	subtext1 = rgb(92, 95, 119),
	subtext0 = rgb(108, 111, 133),
	overlay2 = rgb(124, 127, 147),
	overlay1 = rgb(140, 143, 161),
	overlay0 = rgb(156, 160, 176),
	surface2 = rgb(172, 176, 190),
	surface1 = rgb(188, 192, 204),
	surface0 = rgb(204, 208, 218),
	base = rgb(239, 241, 245),
	mantle = rgb(230, 233, 239),
	crust = rgb(220, 224, 232),
}

function M.withAlpha(color, alpha)
	return { red = color.red, green = color.green, blue = color.blue, alpha = alpha }
end

return M
