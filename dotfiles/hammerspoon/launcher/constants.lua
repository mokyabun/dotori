local mocha = {
  text     = { red = 0.804, green = 0.839, blue = 0.957, alpha = 1 },
  subtext  = { red = 0.651, green = 0.678, blue = 0.784, alpha = 1 },
}

return {
  hotkey   = { mods = { "cmd" }, key = "space" },
  scanDirs = {
    "/Applications",
    "/System/Applications",
    os.getenv("HOME") .. "/Applications",
  },
  dbPath   = hs.configdir .. "/data/launcher.db",
  chooser  = { width = 36, rows = 10, fgColor = mocha.text, subTextColor = mocha.subtext },
}