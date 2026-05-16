local config = require("launcher.constants")
local icons  = require("lib.icons")

local apps = {}

apps.cache = {}

local _watchers = {}
local _debounce

local function scan()
  local result, seen = {}, {}
  for _, dir in ipairs(config.scanDirs) do
    local out = hs.execute(
      "find -L '" .. dir .. "' -maxdepth 2 -name '*.app' -type d 2>/dev/null"
    )
    for path in (out or ""):gmatch("[^\n]+") do
      local name     = path:match("([^/]+)%.app$")
      local info     = hs.application.infoForBundlePath(path)
      local bundleId = info and info["CFBundleIdentifier"]
      if name and bundleId and not seen[bundleId] then
        seen[bundleId] = true
        result[#result + 1] = { name = name, path = path, bundleId = bundleId }
      end
    end
  end

  -- Finder lives outside scanDirs, add it explicitly
  local finderPath = "/System/Library/CoreServices/Finder.app"
  local finderInfo = hs.application.infoForBundlePath(finderPath)
  local finderBundleId = finderInfo and finderInfo["CFBundleIdentifier"]
  if finderBundleId and not seen[finderBundleId] then
    seen[finderBundleId] = true
    result[#result + 1] = { name = "Finder", path = finderPath, bundleId = finderBundleId }
  end

  return result
end

local function rebuild(onDone)
  local fresh = scan()

  -- Apply already-cached icons; collect entries still missing one
  local missing = {}
  for _, a in ipairs(fresh) do
    a.icon = icons.get(a.bundleId)
    if not a.icon then missing[#missing + 1] = a end
  end

  apps.cache = fresh

  if #missing > 0 then
    icons.prefetch(missing, onDone)
  elseif onDone then
    onDone()
  end
end

function apps.start(onReady)
  rebuild(onReady)

  for _, dir in ipairs(config.scanDirs) do
    local watcher = hs.pathwatcher.new(dir, function()
      if _debounce then _debounce:stop() end
      _debounce = hs.timer.doAfter(1, function() rebuild() end)
    end)
    watcher:start()
    _watchers[#_watchers + 1] = watcher
  end
end

function apps.stop()
  for _, watcher in ipairs(_watchers) do watcher:stop() end
  _watchers = {}
  if _debounce then _debounce:stop(); _debounce = nil end
end

return apps