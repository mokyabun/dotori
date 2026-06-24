local Terminal = {}

local BUNDLE_ID = "net.kovidgoyal.kitty"
local AEROSPACE_BIN = "/opt/homebrew/bin/aerospace"
local KITTY_WORKSPACE = "T"
local MODS = { "ctrl", "alt", "cmd" }
local KEY = "t"

local appWatcher
local keepAliveTimer
local toggleHotkey
local transitionTimer
local transitionInFlight = false
local pendingToggle = false
local previousWorkspaceByMonitor = {}
local toggle

local function kittyApp()
	local apps = hs.application.applicationsForBundleID(BUNDLE_ID)
	return (apps and apps[1]) or hs.application.find("kitty")
end

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function aerospace(command)
	return trim(hs.execute(AEROSPACE_BIN .. " " .. command, true))
end

local function focusedWorkspace()
	return aerospace("list-workspaces --focused --format '%{workspace}'")
end

local function focusedMonitorId()
	local monitorId = aerospace("list-monitors --focused --format '%{monitor-id}'")
	if monitorId ~= "" then
		return monitorId
	end
	return "default"
end

local function moveKittyWindowsToWorkspace()
	local windows = hs.execute(AEROSPACE_BIN .. " list-windows --all --format '%{window-id}|%{app-bundle-id}'", true)
	for line in (windows or ""):gmatch("[^\n]+") do
		local windowId, bundleId = line:match("^(%d+)|(.+)$")
		if windowId and bundleId == BUNDLE_ID then
			hs.execute(AEROSPACE_BIN .. " move-node-to-workspace --window-id " .. windowId .. " " .. KITTY_WORKSPACE, true)
		end
	end
end

local function launchInBackground()
	if kittyApp() then
		moveKittyWindowsToWorkspace()
		return
	end
	hs.task.new("/usr/bin/open", nil, { "-gj", "-b", BUNDLE_ID }):start()
	hs.timer.doAfter(0.5, moveKittyWindowsToWorkspace)
end

local function returnToPreviousWorkspace(monitorId)
	local previous = previousWorkspaceByMonitor[monitorId]
	if previous and previous ~= "" and previous ~= KITTY_WORKSPACE then
		aerospace("workspace " .. previous)
	else
		aerospace("workspace-back-and-forth")
	end
end

local function focusKittyWorkspace()
	launchInBackground()
	moveKittyWindowsToWorkspace()
	aerospace("summon-workspace " .. KITTY_WORKSPACE)
	aerospace("workspace " .. KITTY_WORKSPACE)

	hs.timer.doAfter(0.3, function()
		moveKittyWindowsToWorkspace()
		local app = kittyApp()
		if app then
			app:activate(true)
		end
	end)
end

local function finishTransition()
	transitionInFlight = false
	transitionTimer = nil

	if pendingToggle then
		pendingToggle = false
		toggle()
	end
end

local function beginTransition(fn)
	transitionInFlight = true
	if transitionTimer then
		transitionTimer:stop()
	end

	fn()
	transitionTimer = hs.timer.doAfter(0.45, finishTransition)
end

toggle = function()
	if transitionInFlight then
		pendingToggle = not pendingToggle
		return
	end

	local monitorId = focusedMonitorId()
	local workspace = focusedWorkspace()

	if workspace == KITTY_WORKSPACE then
		beginTransition(function()
			returnToPreviousWorkspace(monitorId)
		end)
		return
	end

	previousWorkspaceByMonitor[monitorId] = workspace
	beginTransition(focusKittyWorkspace)
end

function Terminal.start()
	launchInBackground()
	keepAliveTimer = hs.timer.doEvery(30, launchInBackground)

	appWatcher = hs.application.watcher.new(function(_, event, app)
		if app and app:bundleID() == BUNDLE_ID and event == hs.application.watcher.terminated then
			hs.timer.doAfter(1, launchInBackground)
		elseif app and app:bundleID() == BUNDLE_ID and event == hs.application.watcher.launched then
			hs.timer.doAfter(0.5, moveKittyWindowsToWorkspace)
		end
	end)
	appWatcher:start()

	toggleHotkey = hs.hotkey.bind(MODS, KEY, toggle)
end

Terminal.start()

return Terminal
