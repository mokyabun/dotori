local Terminal = {}

local BUNDLE_ID = "net.kovidgoyal.kitty"
local AEROSPACE_BIN = "/opt/homebrew/bin/aerospace"
local MODS = { "ctrl", "alt", "cmd" }
local KEY = "t"

local appWatcher
local keepAliveTimer
local toggleHotkey
local lastWindow

local function kittyApp()
	local apps = hs.application.applicationsForBundleID(BUNDLE_ID)
	return (apps and apps[1]) or hs.application.find("kitty")
end

local function isKittyWindow(window)
	local app = window and window:application()
	return app and app:bundleID() == BUNDLE_ID
end

local function rememberFocusedWindow()
	local window = hs.window.focusedWindow()
	if window and not isKittyWindow(window) then
		lastWindow = window
	end
end

local function isUsableWindow(window)
	if not window then
		return false
	end
	local ok, id = pcall(function()
		return window:id()
	end)
	return ok and id ~= nil
end

local function currentScreen()
	local window = hs.window.focusedWindow()
	return (window and window:screen()) or hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
end

local function launchInBackground()
	if kittyApp() then
		return
	end
	hs.task.new("/usr/bin/open", nil, { "-gj", "-b", BUNDLE_ID }):start()
end

local function kittyWindowOnScreen(app, screen)
	if not app or not screen then
		return nil
	end
	for _, window in ipairs(app:allWindows()) do
		if window:screen() and window:screen():id() == screen:id() and not window:isMinimized() then
			return window
		end
	end
	return nil
end

local function focusPrevious()
	if isUsableWindow(lastWindow) and not isKittyWindow(lastWindow) then
		lastWindow:focus()
		return
	end
	hs.execute(AEROSPACE_BIN .. " focus-back-and-forth", true)
end

local function focusKittyOn(screen)
	hs.application.launchOrFocusByBundleID(BUNDLE_ID)

	hs.timer.doAfter(0.15, function()
		local app = kittyApp()
		if not app then
			return
		end

		app:unhide()
		local window = kittyWindowOnScreen(app, screen)
		if window then
			window:focus()
			return
		end

		app:activate(true)
		hs.timer.doAfter(0.1, function()
			if not kittyWindowOnScreen(app, screen) then
				hs.eventtap.keyStroke({ "cmd" }, "n", 0, app)
			end
			hs.timer.doAfter(0.2, function()
				local target = kittyWindowOnScreen(app, screen) or app:focusedWindow() or app:mainWindow()
				if target then
					target:focus()
				end
			end)
		end)
	end)
end

local function toggle()
	local focused = hs.window.focusedWindow()
	if isKittyWindow(focused) then
		focusPrevious()
		return
	end

	rememberFocusedWindow()
	focusKittyOn(currentScreen())
end

function Terminal.start()
	launchInBackground()
	keepAliveTimer = hs.timer.doEvery(30, launchInBackground)

	appWatcher = hs.application.watcher.new(function(_, event, app)
		if app and app:bundleID() == BUNDLE_ID and event == hs.application.watcher.terminated then
			hs.timer.doAfter(1, launchInBackground)
		end
	end)
	appWatcher:start()

	toggleHotkey = hs.hotkey.bind(MODS, KEY, toggle)
end

Terminal.start()

return Terminal
