-- lib/icons.lua
-- Shared icon and bundleID cache. Persists for the lifetime of Hammerspoon.
--
-- API:
--   icons.get(bundleID)        → hs.image | nil  (cache-only, no I/O)
--   icons.load(bundleID)       → hs.image | nil  (sync load + cache)
--   icons.prefetch(list, onDone)  async batch-load; list items need .bundleId or .bundleID
--   icons.bundleID(appName)    → string | nil    (name → bundleID, cached)

local M = {}

local _icons     = {}   -- bundleID  → hs.image | false
local _bundleIDs = {}   -- appName   → bundleID | false

--- Returns cached icon; nil if not yet loaded (no I/O).
function M.get(bundleID)
  if not bundleID then return nil end
  return _icons[bundleID] or nil   -- false → nil
end

--- Loads and caches icon synchronously. Returns hs.image or nil.
function M.load(bundleID)
  if not bundleID then return nil end
  if _icons[bundleID] == nil then
    _icons[bundleID] = hs.image.imageFromAppBundle(bundleID) or false
  end
  return _icons[bundleID] or nil
end

--- Async batch-loader. Each item in `list` must have .bundleId or .bundleID.
--- Also sets item.icon on each entry. Calls onDone() when finished.
function M.prefetch(list, onDone)
  local i = 0
  local function step()
    i = i + 1
    if i > #list then
      if onDone then onDone() end
      return
    end
    local id = list[i].bundleID or list[i].bundleId
    list[i].icon = M.load(id)
    hs.timer.doAfter(0, step)
  end
  hs.timer.doAfter(0, step)
end

--- Returns the bundleID for a running app by name (cached).
function M.bundleID(appName)
  if not appName then return nil end
  if _bundleIDs[appName] == nil then
    local app = hs.application.get(appName)
    _bundleIDs[appName] = (app and app:bundleID()) or false
  end
  return _bundleIDs[appName] or nil
end

return M