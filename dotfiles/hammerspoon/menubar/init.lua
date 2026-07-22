local socket = require("lib.socket")
local view = require("menubar.view")

local YABAI_BIN = "/opt/homebrew/bin/yabai"

local state = {
	workspaces = {},
	workspacesByMonitorName = {},
	fullscreenByMonitorName = {},
	focused = nil,
	layout = "tiling",
	power = nil,
	caffeinate = { display = false, system = false },
}

local activeQueries = {}

local function queryYabai(selector, onDone)
	local task
	task = hs.task.new(YABAI_BIN, function(exitCode, stdout)
		activeQueries[task] = nil
		if exitCode ~= 0 or stdout == "" then
			onDone(nil)
			return
		end
		local ok, data = pcall(hs.json.decode, stdout)
		onDone(ok and data or nil)
	end, { "-m", "query", selector })

	if not task then
		onDone(nil)
		return
	end
	activeQueries[task] = true
	task:start()
end

local function applyTopology(spaces, displays)
	spaces = spaces or {}
	displays = displays or {}

	local workspaces = {}
	local workspacesByMonitorName = {}
	local fullscreenByMonitorName = {}
	local fullscreenByDisplay = {}
	for _, space in ipairs(spaces) do
		if space["is-visible"] and space["is-native-fullscreen"] then
			fullscreenByDisplay[space.display] = true
		end
		if space["has-focus"] then
			state.focused = tostring(space.index)
		end
	end

	if #displays > 0 then
		for _, display in ipairs(displays) do
			local monitorName = display.uuid or tostring(display.index)
			fullscreenByMonitorName[monitorName] = fullscreenByDisplay[display.index] or false
			local names = {}
			for _, space in ipairs(display.spaces or {}) do
				names[#names + 1] = tostring(space)
			end

			if #names > 0 then
				workspacesByMonitorName[monitorName] = names
			end
			for _, name in ipairs(names) do
				workspaces[#workspaces + 1] = name
			end
		end
	end

	if #workspaces == 0 then
		for _, space in ipairs(spaces) do
			workspaces[#workspaces + 1] = tostring(space.index)
		end
	end

	state.workspaces = workspaces
	state.workspacesByMonitorName = workspacesByMonitorName
	state.fullscreenByMonitorName = fullscreenByMonitorName
end

local topologyRefreshInFlight = false
local topologyRefreshQueued = false
local refreshTopology

refreshTopology = function()
	if topologyRefreshInFlight then
		topologyRefreshQueued = true
		return
	end

	topologyRefreshInFlight = true
	local results = {}
	local pending = 2
	local function complete(name, data)
		results[name] = data
		pending = pending - 1
		if pending > 0 then
			return
		end

		topologyRefreshInFlight = false
		if results.spaces or results.displays then
			applyTopology(results.spaces, results.displays)
			view.refresh(state)
		end
		if topologyRefreshQueued then
			topologyRefreshQueued = false
			refreshTopology()
		end
	end

	queryYabai("--spaces", function(data)
		complete("spaces", data)
	end)
	queryYabai("--displays", function(data)
		complete("displays", data)
	end)
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

refreshCaffeinate()

view.init(state)
refreshTopology()

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
local powerRestartTimer

local function startPowerStream()
	if powerRestartTimer then
		powerRestartTimer:stop()
		powerRestartTimer = nil
	end
	powerTask = hs.task.new("/opt/homebrew/bin/macmon", function()
		powerTask = nil
		powerRestartTimer = hs.timer.doAfter(5, startPowerStream)
	end, function(_, stdout, _)
		for line in stdout:gmatch("[^\n]+") do
			local ok, data = pcall(hs.json.decode, line)
			if ok and data and data.sys_power then
				local power = string.format("%.1fW", data.sys_power)
				if power ~= state.power then
					state.power = power
					view.refreshPower(state)
				end
			end
		end
		return true
	end, { "pipe", "-i", "1000" })
	if powerTask then
		powerTask:start()
	else
		powerRestartTimer = hs.timer.doAfter(5, startPowerStream)
	end
end

startPowerStream()

-- Screen layout changes: recreate bars
local screenWatcher = hs.screen.watcher.new(function()
	refreshCaffeinate()
	view.init(state)
	refreshTopology()
end)
screenWatcher:start()

-- yabai events
socket
	.on("yabai", "ws", function(_, workspace)
		state.focused = workspace
		view.refresh(state)
		refreshTopology()
	end)
	.on("yabai", "refresh", function()
		refreshTopology()
	end)
	.on("yabai", "layout", function(_, layout)
		state.layout = layout
		refreshView()
	end)
	.on("system", "caffeinate", function()
		refreshView()
	end)
