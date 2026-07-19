local socket = require("lib.socket")
local colors = require("lib.colors")
local notify = require("lib.notify")

local layoutIcons = { tiling = "⊞", floating = "⬚" }
local layoutNames = { tiling = "Tiling", floating = "Floating" }

socket
	.on("yabai", "ws", function(_, workspace)
		notify.show({
			icon = "WS",
			title = "Workspace " .. workspace,
			subtitle = "yabai",
			color = colors.lavender,
		})
	end)
	.on("yabai", "layout", function(_, layout)
		notify.show({
			icon = layoutIcons[layout] or "◇",
			title = layoutNames[layout] or layout,
			subtitle = "Layout changed",
			color = colors.sky,
		})
	end)
	.start()
