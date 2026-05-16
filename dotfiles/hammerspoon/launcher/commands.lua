-- Add new commands here. Each entry supports:
--   text    : string displayed in the launcher
--   subText : string or function() -> string (evaluated at show time)
--   icon    : hs.image (optional)
--   fn      : function called on selection

local function caffeinate(key) return hs.caffeinate.get(key) end
local function setCaffeinate(on)
  hs.caffeinate.set("displayIdle", on)
  hs.caffeinate.set("systemIdle",  on)
end

return {
  -- System
  { text = "Lock Screen",        subText = "System", fn = function() hs.caffeinate.lockScreen() end },
  { text = "Sleep",              subText = "System", fn = function() hs.caffeinate.systemSleep() end },
  { text = "Restart",            subText = "System", fn = function() hs.caffeinate.restartSystem() end },
  { text = "Shut Down",          subText = "System", fn = function() hs.caffeinate.shutdownSystem() end },
  { text = "Log Out",            subText = "System", fn = function() hs.caffeinate.logOut() end },
  { text = "Empty Trash",        subText = "System", fn = function() hs.applescript('tell application "Finder" to empty trash') end },
  { text = "Reload Hammerspoon", subText = "System", fn = function() hs.reload() end },
  { text = "Sleep display",      subText = "System", fn = function() hs.task.new("/bin/sh", nil, { "-c", "pmset displaysleepnow" }):start() end },

  -- Caffeinate
  {
    text    = "Toggle Caffeinate",
    subText = function()
      return caffeinate("displayIdle") and "Caffeinate: On" or "Caffeinate: Off"
    end,
    fn = function() setCaffeinate(not caffeinate("displayIdle")) end,
  },

  -- systemIdle만 방지 (화면 슬립은 허용)
  {
    text    = "Toggle Caffeinate (System Only)",
    subText = function()
      return hs.caffeinate.get("systemIdle") and "Caffeinate: On (system only)" or "Caffeinate: Off"
    end,
    fn = function()
      hs.caffeinate.set("systemIdle", not hs.caffeinate.get("systemIdle"), true)
    end,
  },
  
  -- 디스플레이만 즉시 슬립
  {
    text    = "Sleep Display",
    subText = "Sleep display only, system stays awake",
    fn = function()
      hs.execute("pmset displaysleepnow")
    end,
  },

  -- Network
  {
    text    = "Connect to SMB",
    subText = "smb://192.168.10.20",
    fn = function()
      hs.execute("open 'smb://192.168.10.20'")
    end,
  },

  -- RAM Disk
  {
    text    = "Make RAM Disk",
    subText = "Create 4 GB RAM disk at /Volumes/RAMDisk",
    fn = function()
      hs.task.new("/bin/sh", nil, { "-c",
        'diskutil erasevolume HFS+ "RAMDisk" $(hdiutil attach -nomount ram://8388608)'
      }):start()
    end,
  },
  {
    text    = "Eject RAM Disk",
    subText = "Eject /Volumes/RAMDisk",
    fn = function()
      hs.task.new("/bin/sh", nil, { "-c", "diskutil eject RAMDisk" }):start()
    end,
  },
}