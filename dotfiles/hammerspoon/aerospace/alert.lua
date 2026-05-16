local socket = require("lib.socket")

-- Catppuccin Mocha 색상 (jankyborders active_color 0xffb4befe Lavender와 통일)
local alertStyle = {
    strokeColor = { white = 0,     alpha = 0    },
    fillColor   = { red   = 0.071, green = 0.071, blue  = 0.118, alpha = 0.92 },
    textColor   = { red   = 0.706, green = 0.745, blue  = 0.996, alpha = 1    },
    textSize    = 18,
    radius      = 8,
}

local layoutLabels = { tiling = "⊞ Tiling", floating = "⬚ Float" }

socket
  .on("aerospace", "ws", function(_, ws)
    hs.alert.closeAll()
    hs.alert.show("Workspace " .. ws, alertStyle, 1.0)
  end)
  .on("aerospace", "layout", function(_, layout)
    hs.alert.closeAll()
    hs.alert.show(layoutLabels[layout] or layout, alertStyle, 1.0)
  end)
  .start()