local Icons = {}

local iconCache = {} -- bundleID → hs.image | false
local bundleIDCache = {} -- appName  → bundleID | false

function Icons.get(bundleID)
	if not bundleID then
		return nil
	end
	return iconCache[bundleID] or nil
end

function Icons.load(bundleID)
	if not bundleID then
		return nil
	end
	if iconCache[bundleID] == nil then
		iconCache[bundleID] = hs.image.imageFromAppBundle(bundleID) or false
	end
	return iconCache[bundleID] or nil
end

function Icons.prefetch(list, onDone)
	local index = 0
	local function step()
		index = index + 1
		if index > #list then
			if onDone then
				onDone()
			end
			return
		end
		local bundleID = list[index].bundleID or list[index].bundleId
		list[index].icon = Icons.load(bundleID)
		hs.timer.doAfter(0, step)
	end
	hs.timer.doAfter(0, step)
end

function Icons.bundleID(appName)
	if not appName then
		return nil
	end
	if bundleIDCache[appName] == nil then
		local app = hs.application.get(appName)
		bundleIDCache[appName] = (app and app:bundleID()) or false
	end
	return bundleIDCache[appName] or nil
end

return Icons
