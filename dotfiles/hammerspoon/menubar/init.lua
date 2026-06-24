local socket = require("lib.socket")
local view = require("menubar.view")

local AEROSPACE_BIN = "/opt/homebrew/bin/aerospace"

local state = {
	workspaces = {},
	workspacesByMonitorName = {},
	focused = nil,
	layout = "tiling",
	power = nil,
}

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function aerospaceJson(command)
	local output = hs.execute(AEROSPACE_BIN .. " " .. command .. " --json")
	if not output or output == "" then
		return nil
	end
	local ok, data = pcall(hs.json.decode, output)
	if ok then
		return data
	end
	return nil
end

local function workspaceNames(rows)
	local names = {}
	for _, row in ipairs(rows or {}) do
		local name = row.workspace or row
		if name then
			names[#names + 1] = tostring(name)
		end
	end
	return names
end

local function refreshWorkspaces()
	state.workspaces = {}
	state.workspacesByMonitorName = {}

	local monitors = aerospaceJson("list-monitors")
	if monitors and #monitors > 0 then
		for _, monitor in ipairs(monitors) do
			local monitorId = monitor["monitor-id"]
			local monitorName = monitor["monitor-name"]
			local workspaces = workspaceNames(aerospaceJson("list-workspaces --monitor " .. monitorId))

			if monitorName and #workspaces > 0 then
				state.workspacesByMonitorName[monitorName] = workspaces
			end
			for _, workspace in ipairs(workspaces) do
				state.workspaces[#state.workspaces + 1] = workspace
			end
		end
	end

	if #state.workspaces == 0 then
		state.workspaces = workspaceNames(aerospaceJson("list-workspaces --all"))
	end
end

local function refreshFocused()
	local focused = trim(hs.execute(AEROSPACE_BIN .. " list-workspaces --focused"))
	state.focused = focused ~= "" and focused or nil
end

refreshWorkspaces()
refreshFocused()

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
	refreshWorkspaces()
	refreshFocused()
	view.init(state)
end)
screenWatcher:start()

-- Aerospace events
socket
	.on("aerospace", "ws", function(_, workspace)
		state.focused = workspace
		refreshWorkspaces()
		view.refresh(state)
	end)
	.on("aerospace", "layout", function(_, layout)
		state.layout = layout
		view.refresh(state)
	end)
