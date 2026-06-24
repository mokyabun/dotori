local socket = require("lib.socket")

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
local currentWorkspace
local previousWorkspaceByScreen = {}
local toggle

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function kittyApp()
	local apps = hs.application.applicationsForBundleID(BUNDLE_ID)
	return (apps and apps[1]) or hs.application.find("kitty")
end

local function runAerospace(args, onExit)
	hs.task
		.new(AEROSPACE_BIN, function()
			if onExit then
				onExit()
			end
		end, args)
		:start()
end

local function currentScreenKey()
	local screen = (hs.window.focusedWindow() and hs.window.focusedWindow():screen())
		or hs.mouse.getCurrentScreen()
		or hs.screen.mainScreen()
	return (screen and (screen:name() or tostring(screen:id()))) or "default"
end

local function refreshFocusedWorkspace()
	currentWorkspace = trim(hs.execute(AEROSPACE_BIN .. " list-workspaces --focused --format '%{workspace}'", true))
end

local function moveKittyWindowsToWorkspace()
	local windows = hs.execute(AEROSPACE_BIN .. " list-windows --all --format '%{window-id}|%{app-bundle-id}'", true)
	for line in (windows or ""):gmatch("[^\n]+") do
		local windowId, bundleId = line:match("^(%d+)|(.+)$")
		if windowId and bundleId == BUNDLE_ID then
			runAerospace({ "move-node-to-workspace", "--window-id", windowId, KITTY_WORKSPACE })
		end
	end
end

local function launchInBackground()
	if kittyApp() then
		return
	end
	hs.task.new("/usr/bin/open", nil, { "-gj", "-b", BUNDLE_ID }):start()
	hs.timer.doAfter(0.5, moveKittyWindowsToWorkspace)
end

local function returnToPreviousWorkspace(screenKey)
	local previous = previousWorkspaceByScreen[screenKey]
	if previous and previous ~= "" and previous ~= KITTY_WORKSPACE then
		currentWorkspace = previous
		runAerospace({ "workspace", previous })
	else
		runAerospace({ "workspace-back-and-forth" }, refreshFocusedWorkspace)
	end
end

local function focusKittyWorkspace()
	launchInBackground()
	currentWorkspace = KITTY_WORKSPACE
	runAerospace({ "summon-workspace", KITTY_WORKSPACE }, function()
		runAerospace({ "workspace", KITTY_WORKSPACE })
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
	transitionTimer = hs.timer.doAfter(0.28, finishTransition)
end

toggle = function()
	if transitionInFlight then
		pendingToggle = not pendingToggle
		return
	end

	local screenKey = currentScreenKey()
	local workspace = currentWorkspace
	if not workspace or workspace == "" then
		refreshFocusedWorkspace()
		workspace = currentWorkspace
	end

	if workspace == KITTY_WORKSPACE then
		beginTransition(function()
			returnToPreviousWorkspace(screenKey)
		end)
		return
	end

	previousWorkspaceByScreen[screenKey] = workspace
	beginTransition(focusKittyWorkspace)
end

function Terminal.start()
	refreshFocusedWorkspace()
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

	socket.on("aerospace", "ws", function(_, workspace)
		currentWorkspace = workspace
	end)

	toggleHotkey = hs.hotkey.bind(MODS, KEY, toggle)
end

Terminal.start()

return Terminal
