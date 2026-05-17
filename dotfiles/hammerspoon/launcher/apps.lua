local config = require("launcher.constants")
local icons = require("lib.icons")

local Apps = {}

Apps.cache = {}

local dirWatchers = {}
local debounceTimer

local function scan()
	local result = {}
	local seen = {}

	for _, dir in ipairs(config.scanDirs) do
		local output = hs.execute("find -L '" .. dir .. "' -maxdepth 2 -name '*.app' -type d 2>/dev/null")
		for appPath in (output or ""):gmatch("[^\n]+") do
			local appName = appPath:match("([^/]+)%.app$")
			local info = hs.application.infoForBundlePath(appPath)
			local bundleId = info and info["CFBundleIdentifier"]
			if appName and bundleId and not seen[bundleId] then
				seen[bundleId] = true
				result[#result + 1] = { name = appName, path = appPath, bundleId = bundleId }
			end
		end
	end

	local finderPath = "/System/Library/CoreServices/Finder.app"
	local finderInfo = hs.application.infoForBundlePath(finderPath)
	local finderBundleId = finderInfo and finderInfo["CFBundleIdentifier"]
	if finderBundleId and not seen[finderBundleId] then
		result[#result + 1] = { name = "Finder", path = finderPath, bundleId = finderBundleId }
	end

	return result
end

local function rebuild(onDone)
	local fresh = scan()
	local missing = {}

	for _, app in ipairs(fresh) do
		app.icon = icons.get(app.bundleId)
		if not app.icon then
			missing[#missing + 1] = app
		end
	end

	Apps.cache = fresh

	if #missing > 0 then
		icons.prefetch(missing, onDone)
	elseif onDone then
		onDone()
	end
end

function Apps.start(onReady)
	rebuild(onReady)

	for _, dir in ipairs(config.scanDirs) do
		local watcher = hs.pathwatcher.new(dir, function()
			if debounceTimer then
				debounceTimer:stop()
			end
			debounceTimer = hs.timer.doAfter(1, function()
				rebuild()
			end)
		end)
		watcher:start()
		dirWatchers[#dirWatchers + 1] = watcher
	end
end

function Apps.stop()
	for _, watcher in ipairs(dirWatchers) do
		watcher:stop()
	end
	dirWatchers = {}
	if debounceTimer then
		debounceTimer:stop()
		debounceTimer = nil
	end
end

return Apps
