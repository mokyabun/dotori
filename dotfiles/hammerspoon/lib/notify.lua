local colors = require("lib.colors")

local Notify = {}

local FONT = "JetBrainsMono Nerd Font"
local WIDTH = 318
local HEIGHT = 76
local PADDING = 12
local ICON_SIZE = 34
local GAP = 10
local DEFAULT_DURATION = 1.4

local activeCanvas
local activeTimer

local function styled(str, size, color, alignment)
	return hs.styledtext.new(str or "", {
		font = { name = FONT, size = size },
		color = color,
		paragraphStyle = { alignment = alignment or "left" },
	})
end

local function close()
	if activeTimer then
		activeTimer:stop()
		activeTimer = nil
	end
	if activeCanvas then
		activeCanvas:delete()
		activeCanvas = nil
	end
end

local function screenFrame()
	local screen = hs.screen.mainScreen()
	return screen and screen:frame() or { x = 0, y = 0, w = 1440, h = 900 }
end

function Notify.show(options)
	if type(options) == "string" then
		options = { title = options }
	end
	options = options or {}

	close()

	local accent = options.color or colors.lavender
	local title = options.title or ""
	local subtitle = options.subtitle or options.subText or ""
	local icon = options.icon or "*"
	local duration = options.duration or DEFAULT_DURATION
	local frame = screenFrame()
	local x = frame.x + frame.w - WIDTH - 64
	local y = frame.y + 38

	activeCanvas = hs.canvas.new({ x = x, y = y, w = WIDTH, h = HEIGHT })
	activeCanvas:level(hs.canvas.windowLevels["mainMenu"])
	activeCanvas:alpha(0.98)
	activeCanvas:appendElements({
		{
			type = "rectangle",
			action = "fill",
			fillColor = colors.withAlpha(colors.crust, 0.94),
			roundedRectRadii = { xRadius = 9, yRadius = 9 },
			frame = { x = 0, y = 0, w = WIDTH, h = HEIGHT },
		},
		{
			type = "rectangle",
			action = "fill",
			fillColor = colors.withAlpha(accent, 0.18),
			roundedRectRadii = { xRadius = 7, yRadius = 7 },
			frame = { x = PADDING, y = PADDING, w = ICON_SIZE, h = ICON_SIZE },
		},
		{
			type = "text",
			text = styled(icon, 18, accent, "center"),
			frame = { x = PADDING, y = PADDING + 7, w = ICON_SIZE, h = ICON_SIZE },
		},
		{
			type = "text",
			text = styled(title, 13, colors.text),
			frame = {
				x = PADDING + ICON_SIZE + GAP,
				y = PADDING + 6,
				w = WIDTH - PADDING * 2 - ICON_SIZE - GAP,
				h = 18,
			},
		},
		{
			type = "text",
			text = styled(subtitle, 11, colors.overlay2),
			frame = {
				x = PADDING + ICON_SIZE + GAP,
				y = PADDING + 28,
				w = WIDTH - PADDING * 2 - ICON_SIZE - GAP,
				h = 18,
			},
		},
		{
			type = "rectangle",
			action = "fill",
			fillColor = accent,
			roundedRectRadii = { xRadius = 1, yRadius = 1 },
			frame = { x = PADDING, y = HEIGHT - 13, w = WIDTH - PADDING * 2, h = 2 },
		},
	})

	activeCanvas:show()
	activeTimer = hs.timer.doAfter(duration, close)
	return activeCanvas
end

function Notify.close()
	close()
end

return Notify
