local socket = require("lib.socket")
local view = require("menubar.view")

local AEROSPACE_BIN = "/opt/homebrew/bin/aerospace"

local state = {
	workspaces = {},
	focused = nil,
	layout = "tiling",
	power = nil,
}

-- Bootstrap initial state from aerospace
local wsOut = hs.execute(AEROSPACE_BIN .. " list-workspaces --all")
for line in wsOut:gmatch("[^\n]+") do
	if line ~= "" then
		state.workspaces[#state.workspaces + 1] = line
	end
end
local focused = hs.execute(AEROSPACE_BIN .. " list-workspaces --focused"):match("^%s*(.-)%s*$")
state.focused = focused ~= "" and focused or nil

view.init(state)

-- Clock: tick aligned to minute boundaries
local clockTimer, syncTimer

local function startClockTimer()
	if clockTimer then
		clockTimer:stop()
	end
	clockTimer = hs.timer.new(60, function()
		view.refresh(state)
	end)
	clockTimer:start()
end

local function scheduleClock()
	if syncTimer then
		syncTimer:stop()
	end
	if clockTimer then
		clockTimer:stop()
		clockTimer = nil
	end
	local delay = 60 - (os.time() % 60)
	syncTimer = hs.timer.doAfter(delay, function()
		view.refresh(state)
		startClockTimer()
		syncTimer = nil
	end)
end

scheduleClock()

-- Wake from sleep: refresh immediately and resync clock
local caffeWatcher = hs.caffeinate.watcher.new(function(event)
	if event == hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensDidWake then
		view.refresh(state)
		scheduleClock()
	end
end)
caffeWatcher:start()

-- Power: stream from macmon, restart on crash
local powerTask

local function startPowerStream()
	if powerTask and powerTask:isRunning() then
		powerTask:terminate()
	end
	powerTask = hs.task.new("/opt/homebrew/bin/macmon", function()
		hs.timer.doAfter(5, startPowerStream)
	end, function(_, stdout, _)
		for line in stdout:gmatch("[^\n]+") do
			local ok, data = pcall(hs.json.decode, line)
			if ok and data and data.sys_power then
				state.power = string.format("%.1fW", data.sys_power)
				view.refresh(state)
			end
		end
		return true
	end, { "pipe", "-i", "1000" })
	powerTask:start()
end

startPowerStream()

-- Screen layout changes: recreate bars
local screenWatcher = hs.screen.watcher.new(function()
	view.init(state)
end)
screenWatcher:start()

-- Aerospace events
socket
	.on("aerospace", "ws", function(_, workspace)
		state.focused = workspace
		view.refresh(state)
	end)
	.on("aerospace", "layout", function(_, layout)
		state.layout = layout
		view.refresh(state)
	end)
