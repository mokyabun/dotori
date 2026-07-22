-- Catppuccin official color palettes. The flattened values remain Latte for
-- existing consumers; individual components can opt into another flavor.
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

M.mocha = {
	rosewater = rgb(245, 224, 220),
	flamingo = rgb(242, 205, 205),
	pink = rgb(245, 194, 231),
	mauve = rgb(203, 166, 247),
	red = rgb(243, 139, 168),
	maroon = rgb(235, 160, 172),
	peach = rgb(250, 179, 135),
	yellow = rgb(249, 226, 175),
	green = rgb(166, 227, 161),
	teal = rgb(148, 226, 213),
	sky = rgb(137, 220, 235),
	sapphire = rgb(116, 199, 236),
	blue = rgb(137, 180, 250),
	lavender = rgb(180, 190, 254),
	text = rgb(205, 214, 244),
	subtext1 = rgb(186, 194, 222),
	subtext0 = rgb(166, 173, 200),
	overlay2 = rgb(147, 153, 178),
	overlay1 = rgb(127, 132, 156),
	overlay0 = rgb(108, 112, 134),
	surface2 = rgb(88, 91, 112),
	surface1 = rgb(69, 71, 90),
	surface0 = rgb(49, 50, 68),
	base = rgb(30, 30, 46),
	mantle = rgb(24, 24, 37),
	crust = rgb(17, 17, 27),
}

function M.withAlpha(color, alpha)
	return { red = color.red, green = color.green, blue = color.blue, alpha = alpha }
end

return M
