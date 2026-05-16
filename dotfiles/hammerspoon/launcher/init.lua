local config   = require("launcher.constants")
local db       = require("launcher.db")
local apps     = require("launcher.apps")
local frecency = require("launcher.frecency")
local commands = require("launcher.commands")

local _chooser
local _appWatcher
local _registry = {}

local function buildChoices()
  _registry = {}

  local running = {}
  for _, app in ipairs(hs.application.runningApplications()) do
    local name = app:name()
    if name then running[name] = true end
  end

  local list = {}
  for _, a in ipairs(apps.cache) do list[#list + 1] = a end
  frecency.sort(list)

  local choices = {}

  for _, a in ipairs(list) do
    local key = "app:" .. a.bundleId
    _registry[key] = { kind = "app", path = a.path, bundleId = a.bundleId }
    choices[#choices + 1] = {
      text    = a.name,
      subText = running[a.name] and "Running" or "",
      image   = a.icon,
      uuid    = key,
    }
  end

  for i, cmd in ipairs(commands) do
    local key = "cmd:" .. i
    _registry[key] = { kind = "cmd", fn = cmd.fn }
    choices[#choices + 1] = {
      text    = cmd.text,
      subText = type(cmd.subText) == "function" and cmd.subText() or (cmd.subText or ""),
      image   = cmd.icon,
      uuid    = key,
    }
  end

  return choices
end

local function onChoice(item)
  if not item then return end
  local handler = _registry[item.uuid]
  if not handler then return end
  if handler.kind == "cmd" then
    handler.fn()
  else
    frecency.record(handler.bundleId)
    hs.application.open(handler.path)
  end
end

local function show()
  _chooser:choices(buildChoices())
  _chooser:show()
end

local database = db.open()
frecency.init(database)

_chooser = hs.chooser.new(onChoice)
_chooser:placeholderText("Search apps and commands…")
_chooser:searchSubText(false)
_chooser:width(config.chooser.width)
_chooser:rows(config.chooser.rows)
_chooser:bgDark(true)
_chooser:fgColor(config.chooser.fgColor)
_chooser:subTextColor(config.chooser.subTextColor)

apps.start(function()
  if _chooser:isVisible() then
    _chooser:choices(buildChoices())
  end
end)

_appWatcher = hs.application.watcher.new(function(_, event, app)
  if event == hs.application.watcher.launched and app then
    local bundleId = app:bundleID()
    if bundleId then frecency.record(bundleId) end
  end
end)
_appWatcher:start()

hs.hotkey.bind(config.hotkey.mods, config.hotkey.key, show)