local FRemap = require('remap.foundation_remapping')

local remapper = FRemap.new()

-- rcmd -> f19
remapper:remap('rcmd', 'f19')
-- capslock -> f18  (aerospace.nix에서 f18+key 바인딩으로 직접 처리)
remapper:remap('capslock', 'f18')
remapper:register()

local f18_keycode = hs.keycodes.map["f18"]
local is_meh_pressed = false

local function mehKeyHandler(event)
    local keyCode = event:getKeyCode()

    if keyCode == f18_keycode then
        is_meh_pressed = (event:getType() == hs.eventtap.event.types.keyDown)
        return true -- f18 이벤트를 시스템으로 전달하지 않음
    end

    if is_meh_pressed then
        local flags = event:getFlags()
        flags.ctrl = true
        flags.cmd  = true
        flags.alt  = true
        event:setFlags(flags)
    end

    return false
end


keyHandler = hs.eventtap.new(
    { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp },
    mehKeyHandler
):start()