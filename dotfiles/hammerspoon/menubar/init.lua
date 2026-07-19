local socket = require("lib.socket")
local view = require("menubar.view")

local YABAI_BIN = "/opt/homebrew/bin/yabai"

local state = {
	workspaces = {},
	workspacesByMonitorName = {},
	focused = nil,
	layout = "tiling",
	power = nil,
	caffeinate = { display = false, system = false },
}

local function yabaiJson(command)
	local output = hs.execute(YABAI_BIN .. " -m query " .. command)
	if not output or output == "" then
		return nil
	end
	local ok, data = pcall(hs.json.decode, output)
	if ok then
		return data
	end
	return nil
end

local function refreshWorkspaces()
	state.workspaces = {}
	state.workspacesByMonitorName = {}

	local displays = yabaiJson("--displays")
	if displays and #displays > 0 then
		for _, display in ipairs(displays) do
			local monitorName = tostring(display.index)
			local names = {}
			for _, space in ipairs(display.spaces or {}) do
				names[#names + 1] = tostring(space)
			end

			if #names > 0 then
				state.workspacesByMonitorName[monitorName] = names
			end
			for _, name in ipairs(names) do
				state.workspaces[#state.workspaces + 1] = name
			end
		end
	end

	if #state.workspaces == 0 then
		for _, space in ipairs(yabaiJson("--spaces") or {}) do
			state.workspaces[#state.workspaces + 1] = tostring(space.index)
		end
	end
end

local function refreshFocused()
	local focused = yabaiJson("--spaces --space")
	state.focused = focused and tostring(focused.index) or nil
end

local function refreshCaffeinate()
	state.caffeinate = {
		display = hs.caffeinate.get("displayIdle"),
		system = hs.caffeinate.get("systemIdle"),
	}
end

local function refreshView()
	refreshCaffeinate()
	view.refresh(state)
end

refreshWorkspaces()
refreshFocused()
refreshCaffeinate()

view.init(state)

-- Clock: tick aligned to minute boundaries
local clockTimer, syncTimer

local function startClockTimer()
	if clockTimer then
		clockTimer:stop()
	end
	clockTimer = hs.timer.new(60, function()
		refreshView()
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
		refreshView()
		startClockTimer()
		syncTimer = nil
	end)
end

scheduleClock()

-- Wake from sleep: refresh immediately and resync clock
local caffeWatcher = hs.caffeinate.watcher.new(function(event)
	if event == hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensDidWake then
		refreshView()
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
				refreshView()
			end
		end
		return true
	end, { "pipe", "-i", "1000" })
	powerTask:start()
end

startPowerStream()

-- Screen layout changes: recreate bars
local screenWatcher = hs.screen.watcher.new(function()
	refreshWorkspaces()
	refreshFocused()
	refreshCaffeinate()
	view.init(state)
end)
screenWatcher:start()

-- yabai events
socket
	.on("yabai", "ws", function(_, workspace)
		state.focused = workspace
		refreshWorkspaces()
		refreshView()
	end)
	.on("yabai", "layout", function(_, layout)
		state.layout = layout
		refreshView()
	end)
	.on("system", "caffeinate", function()
		refreshView()
	end)
