local function getCaffeinate(key)
	return hs.caffeinate.get(key)
end

local function setCaffeinate(enabled)
	hs.caffeinate.set("displayIdle", enabled)
	hs.caffeinate.set("systemIdle", enabled)
end

return {
	-- System
	{
		text = "Lock Screen",
		subText = "System",
		fn = function()
			hs.caffeinate.lockScreen()
		end,
	},
	{
		text = "Sleep",
		subText = "System",
		fn = function()
			hs.caffeinate.systemSleep()
		end,
	},
	{
		text = "Restart",
		subText = "System",
		fn = function()
			hs.caffeinate.restartSystem()
		end,
	},
	{
		text = "Shut Down",
		subText = "System",
		fn = function()
			hs.caffeinate.shutdownSystem()
		end,
	},
	{
		text = "Log Out",
		subText = "System",
		fn = function()
			hs.caffeinate.logOut()
		end,
	},
	{
		text = "Empty Trash",
		subText = "System",
		fn = function()
			hs.applescript('tell application "Finder" to empty trash')
		end,
	},
	{
		text = "Reload Hammerspoon",
		subText = "System",
		fn = function()
			hs.reload()
		end,
	},
	{
		text = "Reload AeroSpace",
		subText = "System",
		fn = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, { "reload-config", "--no-gui" }):start()
		end,
	},
	{
		text = "Sleep Display",
		subText = "Sleep display only, system stays awake",
		fn = function()
			hs.execute("pmset displaysleepnow")
		end,
	},

	-- Caffeinate
	{
		text = "Toggle Caffeinate",
		subText = function()
			return getCaffeinate("displayIdle") and "Caffeinate: On" or "Caffeinate: Off"
		end,
		fn = function()
			setCaffeinate(not getCaffeinate("displayIdle"))
		end,
	},
	{
		text = "Toggle Caffeinate (System Only)",
		subText = function()
			return hs.caffeinate.get("systemIdle") and "Caffeinate: On (system only)" or "Caffeinate: Off"
		end,
		fn = function()
			hs.caffeinate.set("systemIdle", not hs.caffeinate.get("systemIdle"), true)
		end,
	},

	-- RAM Disk
	{
		text = "Make RAM Disk",
		subText = "Create 16 GB RAM disk at /Volumes/RAMDisk",
		fn = function()
			hs.task
				.new(
					"/bin/sh",
					nil,
					{ "-c", 'diskutil erasevolume HFS+ "RAMDisk" $(hdiutil attach -nomount ram://33554432)' }
				)
				:start()
		end,
	},
	{
		text = "Eject RAM Disk",
		subText = "Eject /Volumes/RAMDisk",
		fn = function()
			hs.task.new("/bin/sh", nil, { "-c", "diskutil eject RAMDisk" }):start()
		end,
	},
}
