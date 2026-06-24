local C = require("menubar.constants")

local View = {}

-- entries[screenId] = { canvas = hs.canvas, h = number }
local entries = {}

local DAYS = { "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" }

local function styled(str, size, color)
	return hs.styledtext.new(str, {
		font = { name = C.FONT, size = size },
		color = color,
		paragraphStyle = { alignment = "center" },
	})
end

local function screenWorkspaces(state, screen)
	local name = screen:name()
	return (name and state.workspacesByMonitorName and state.workspacesByMonitorName[name]) or state.workspaces
end

local function drawOn(canvas, h, state, screen)
	canvas:replaceElements()

	local w = C.BAR_W

	-- Background (full height)
	canvas:appendElements({
		type = "rectangle",
		action = "fill",
		fillColor = C.BG,
		frame = { x = 0, y = 0, w = w, h = h },
	})

	local function divLine(dy)
		canvas:appendElements({
			type = "rectangle",
			action = "fill",
			fillColor = C.DIV,
			frame = { x = 6, y = dy, w = w - 12, h = C.DIV_H },
		})
	end

	local function textItem(str, size, color, iy)
		canvas:appendElements({
			type = "text",
			text = styled(str, size, color),
			frame = {
				x = 0,
				y = iy + math.floor((C.ITEM_H - size) / 2),
				w = w,
				h = size + 2,
			},
		})
	end

	-- TOP: day / date / time
	local t = os.time()
	local day = DAYS[tonumber(os.date("%w", t)) + 1]

	textItem(day, C.DAY_SIZE, C.DIM, C.PAD + C.MARGIN_Y)
	textItem(os.date("%m.%d", t), C.DATE_SIZE, C.MUTED, C.PAD + C.MARGIN_Y + C.ITEM_H)
	textItem(os.date("%H:%M", t), C.TIME_SIZE, C.TEXT, C.PAD + C.MARGIN_Y + 2 * C.ITEM_H)

	local topDiv = C.PAD + C.MARGIN_Y + 3 * C.ITEM_H + C.SECTION_GAP
	divLine(topDiv)

	-- BOTTOM: caffeinate status + power
	local caffeine = state.caffeinate or {}
	local caffeineText = "IDLE"
	local caffeineColor = C.DIM
	if caffeine.display then
		caffeineText = "CAF"
		caffeineColor = C.GOOD
	elseif caffeine.system then
		caffeineText = "SYS"
		caffeineColor = C.WARN
	end

	local bottomItems = 2
	local bottomBlockH = bottomItems * C.ITEM_H + (bottomItems - 1) * C.ITEM_GAP
	local botDiv = h - C.PAD - bottomBlockH - C.SECTION_GAP - C.DIV_H
	divLine(botDiv)
	local bottomY = botDiv + C.DIV_H + C.SECTION_GAP
	textItem(caffeineText, C.CAFFEINE_SIZE, caffeineColor, bottomY)
	textItem(state.power or "—", C.POWER_SIZE, C.DIM, bottomY + C.ITEM_H + C.ITEM_GAP)

	-- MIDDLE: workspaces, vertically centered in the remaining space
	local midStart = topDiv + C.DIV_H + C.SECTION_GAP
	local midEnd = botDiv - C.SECTION_GAP
	local workspaces = screenWorkspaces(state, screen)
	local wsCount = #workspaces
	local wsBlockH = wsCount * C.ITEM_H + math.max(0, wsCount - 1) * C.ITEM_GAP
	local wsY = midStart + math.floor((midEnd - midStart - wsBlockH) / 2)

	for i, ws in ipairs(workspaces) do
		local active = ws == state.focused
		if active then
			canvas:appendElements({
				type = "rectangle",
				action = "fill",
				fillColor = C.ACTIVE_BG,
				frame = { x = 4, y = wsY, w = w - 8, h = C.ITEM_H },
			})
		end
		textItem(ws, C.WS_SIZE, active and C.TEXT or C.MUTED, wsY)
		wsY = wsY + C.ITEM_H + (i < wsCount and C.ITEM_GAP or 0)
	end
end

function View.init(state)
	for _, e in pairs(entries) do
		e.canvas:delete()
	end
	entries = {}

	for _, screen in ipairs(hs.screen.allScreens()) do
		local sf = screen:fullFrame()
		local canvas = hs.canvas.new({
			x = sf.x + sf.w - C.MARGIN_X - C.BAR_W,
			y = sf.y,
			w = C.BAR_W,
			h = sf.h,
		})
		canvas:level(hs.canvas.windowLevels["mainMenu"])
		drawOn(canvas, sf.h, state, screen)
		canvas:show()
		entries[screen:id()] = { canvas = canvas, h = sf.h, screen = screen }
	end
end

function View.refresh(state)
	for _, e in pairs(entries) do
		drawOn(e.canvas, e.h, state, e.screen)
	end
end

function View.destroy()
	for _, e in pairs(entries) do
		e.canvas:delete()
	end
	entries = {}
end

return View
