local aerospace = "/opt/homebrew/bin/aerospace"
local icons     = require("lib.icons")

-- Layout constants
local PANEL_W   = 340
local ITEM_H    = 54
local ICON_SIZE = 32
local PAD_X     = 14
local PAD_Y     = 10
local ICON_PAD  = 11
local TEXT_X    = PAD_X + ICON_PAD + ICON_SIZE + 10

-- Canvas element indices (1-based)
local IDX_HL_FILL   = 2
local IDX_HL_BORDER = 3
local IDX_ITEMS     = 4   -- 3 elements per item: icon, name, title

local currentWindows = {}
local selectedIndex  = 1
local isActive       = false
local switcherCanvas = nil

-- ── window list ───────────────────────────────────────────────────────────────

local function getWindows(allWorkspaces)
  local flag = allWorkspaces and "--all" or "--workspace focused"
  local out = hs.execute(
    aerospace .. " list-windows " .. flag ..
    " --format '%{window-id}|%{app-name}|%{window-title}'"
  )
  local windows = {}
  for line in out:gmatch("[^\n]+") do
    local id, app, title = line:match("([^|]+)|([^|]+)|([^|]+)")
    if id then
      local bundleID = icons.bundleID(app)
      windows[#windows + 1] = {
        windowId = id:gsub("%s+", ""),
        app      = app,
        title    = title or "",
        icon     = icons.load(bundleID),
      }
    end
  end
  return windows
end

-- ── highlight update (cheap path, no canvas rebuild) ─────────────────────────

local function updateHighlight()
  if not switcherCanvas then return end
  local iy = PAD_Y + (selectedIndex - 1) * ITEM_H
  local f  = { x = 4, y = iy, w = PANEL_W - 8, h = ITEM_H }
  switcherCanvas[IDX_HL_FILL].frame   = f
  switcherCanvas[IDX_HL_BORDER].frame = f
end

-- ── full canvas build (once per switcher open) ────────────────────────────────

local function buildCanvas()
  if switcherCanvas then switcherCanvas:delete(); switcherCanvas = nil end
  if #currentWindows == 0 then return end

  local n      = #currentWindows
  local panelH = n * ITEM_H + PAD_Y * 2
  local screen = hs.screen.mainScreen():frame()

  switcherCanvas = hs.canvas.new({
    x = screen.x + (screen.w - PANEL_W) / 2,
    y = screen.y + (screen.h - panelH)  / 2,
    w = PANEL_W,
    h = panelH,
  })

  -- [1] background
  switcherCanvas:appendElements({
    type             = "rectangle",
    action           = "fill",
    fillColor        = { red = 0.12, green = 0.12, blue = 0.12, alpha = 0.94 },
    roundedRectRadii = { xRadius = 14, yRadius = 14 },
    frame            = { x = 0, y = 0, w = PANEL_W, h = panelH },
  })

  -- [2] highlight fill (frame updated by updateHighlight)
  switcherCanvas:appendElements({
    type             = "rectangle",
    action           = "fill",
    fillColor        = { red = 1, green = 1, blue = 1, alpha = 0.12 },
    roundedRectRadii = { xRadius = 8, yRadius = 8 },
    frame            = { x = 4, y = PAD_Y, w = PANEL_W - 8, h = ITEM_H },
  })

  -- [3] highlight border
  switcherCanvas:appendElements({
    type             = "rectangle",
    action           = "stroke",
    strokeColor      = { red = 0.45, green = 0.62, blue = 1, alpha = 0.85 },
    strokeWidth      = 1.5,
    roundedRectRadii = { xRadius = 8, yRadius = 8 },
    frame            = { x = 4, y = PAD_Y, w = PANEL_W - 8, h = ITEM_H },
  })

  -- [4..] items (icon + name + title), positioned below
  for _, win in ipairs(currentWindows) do
    if win.icon then
      switcherCanvas:appendElements({
        type       = "image",
        image      = win.icon,
        imageAlpha = 1,
        frame      = { x = 0, y = 0, w = ICON_SIZE, h = ICON_SIZE },
      })
    else
      switcherCanvas:appendElements({
        type = "rectangle", action = "skip",
        frame = { x = 0, y = 0, w = 0, h = 0 },
      })
    end
    switcherCanvas:appendElements({
      type          = "text",
      text          = win.app,
      textColor     = { white = 1, alpha = 0.95 },
      textSize      = 13,
      textAlignment = "left",
      frame         = { x = 0, y = 0, w = PANEL_W - TEXT_X - PAD_X, h = 18 },
    })
    switcherCanvas:appendElements({
      type          = "text",
      text          = win.title,
      textColor     = { white = 0.55, alpha = 1 },
      textSize      = 11,
      textAlignment = "left",
      frame         = { x = 0, y = 0, w = PANEL_W - TEXT_X - PAD_X, h = 16 },
    })
  end

  -- Set per-item frames in one pass
  for i = 1, n do
    local iy   = PAD_Y + (i - 1) * ITEM_H
    local base = IDX_ITEMS + (i - 1) * 3
    switcherCanvas[base].frame     = { x = PAD_X + ICON_PAD, y = iy + (ITEM_H - ICON_SIZE) / 2, w = ICON_SIZE, h = ICON_SIZE }
    switcherCanvas[base + 1].frame = { x = TEXT_X, y = iy + 7,  w = PANEL_W - TEXT_X - PAD_X, h = 18 }
    switcherCanvas[base + 2].frame = { x = TEXT_X, y = iy + 27, w = PANEL_W - TEXT_X - PAD_X, h = 16 }
  end

  updateHighlight()
  switcherCanvas:show()
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────

local function destroySwitcher()
  if switcherCanvas then switcherCanvas:delete(); switcherCanvas = nil end
  isActive       = false
  currentWindows = {}
  selectedIndex  = 1
end

local function showSwitcher(allWorkspaces)
  currentWindows = getWindows(allWorkspaces)
  if #currentWindows == 0 then return end
  isActive      = true
  selectedIndex = #currentWindows > 1 and 2 or 1
  buildCanvas()
end

local function nextItem()
  if #currentWindows == 0 then return end
  selectedIndex = (selectedIndex % #currentWindows) + 1
  updateHighlight()
end

local function prevItem()
  if #currentWindows == 0 then return end
  selectedIndex = ((selectedIndex - 2) % #currentWindows) + 1
  updateHighlight()
end

local function confirmSelection()
  if isActive and #currentWindows > 0 then
    hs.execute(aerospace .. " focus --window-id " .. currentWindows[selectedIndex].windowId)
  end
  destroySwitcher()
end

-- ── event taps ────────────────────────────────────────────────────────────────

tapCmdTab = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local flags   = event:getFlags()
  local chars   = event:getCharacters()
  local keyCode = event:getKeyCode()

  if isActive then
    if keyCode == 53 then                                          -- Escape → cancel
      destroySwitcher()
    elseif chars == "\t" and flags:containExactly { "cmd" } then
      nextItem()
    elseif chars == "\t" and flags:containExactly { "cmd", "shift" } then
      prevItem()
    end
    return true
  end

  if chars == "\t" and flags:containExactly { "cmd" } then
    showSwitcher(false); return true
  elseif chars == "\t" and flags:containExactly { "cmd", "shift" } then
    showSwitcher(true);  return true
  end

  return false
end)

-- Cmd released → confirm
tapCmdRelease = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
  if isActive and not event:getFlags()["cmd"] then confirmSelection() end
  return false
end)

tapCmdTab:start()
tapCmdRelease:start()