local Terminal = {}

local BUNDLE_ID = "net.kovidgoyal.kitty"
local AEROSPACE_BIN = "/opt/homebrew/bin/aerospace"
local KITTY_WORKSPACE = "T"

local appWatcher
local keepAliveTimer

local function kittyApp()
	local apps = hs.application.applicationsForBundleID(BUNDLE_ID)
	return (apps and apps[1]) or hs.application.find("kitty")
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
		return
	end
	hs.task.new("/usr/bin/open", nil, { "-gj", "-b", BUNDLE_ID }):start()
	hs.timer.doAfter(0.5, moveKittyWindowsToWorkspace)
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
end

Terminal.start()

return Terminal
