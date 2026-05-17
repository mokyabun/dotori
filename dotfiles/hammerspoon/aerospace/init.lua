local socket = require("lib.socket")
local colors = require("lib.colors")

local alertStyle = {
	strokeColor = { white = 0, alpha = 0 },
	fillColor = colors.withAlpha(colors.crust, 0.92),
	textColor = colors.lavender,
	textSize = 18,
	radius = 8,
}

local layoutIcons = { tiling = "⊞", floating = "⬚" }

socket
	.on("aerospace", "ws", function(_, workspace)
		hs.alert.closeAll()
		hs.alert.show("Workspace " .. workspace, alertStyle, 1.0)
	end)
	.on("aerospace", "layout", function(_, layout)
		hs.alert.closeAll()
		hs.alert.show(layoutIcons[layout] or layout, alertStyle, 1.0)
	end)
	.start()
