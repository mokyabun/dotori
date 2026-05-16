-- Lightweight UDP event router: message format is "namespace action value"
local EventRouter = {
    port = 9001,
    _handlers = {},
    _socket = nil,
}

-- Dispatch incoming message to all registered handlers
local function dispatch(ns, action, value)
    local bucket = EventRouter._handlers[ns]
    if not bucket then return end
    for _, fn in ipairs(bucket[action] or {}) do fn(action, value) end
    for _, fn in ipairs(bucket["*"]    or {}) do fn(action, value) end
end

-- Register handler: on(ns, fn) catches all actions, on(ns, action, fn) catches one
-- Multiple handlers per event are supported and all will be called.
function EventRouter.on(ns, action, fn)
    if type(action) == "function" then
        fn, action = action, "*"
    end
    EventRouter._handlers[ns] = EventRouter._handlers[ns] or {}
    local list = EventRouter._handlers[ns][action] or {}
    list[#list + 1] = fn
    EventRouter._handlers[ns][action] = list
    return EventRouter
end

EventRouter.register = EventRouter.on

-- Start the UDP listener; call once from your init file
function EventRouter.start(port)
    if port then EventRouter.port = port end
    EventRouter._socket = hs.socket.udp.new(function(data, _addr)
        local ns, action, value = data:match("^(%S+)%s+(%S+)%s*(.*)")
        if ns then
            dispatch(ns, action, value ~= "" and value or nil)
        end
        EventRouter._socket:receive()
    end)
    EventRouter._socket:listen(EventRouter.port):receive()
    return EventRouter
end

-- Send a UDP message to the router from any script or HS module
function EventRouter.send(ns, action, value, port, host)
    local msg = ns .. " " .. action .. (value and (" " .. value) or "")
    local sock = hs.socket.udp.new()
    sock:send(msg, host or "127.0.0.1", port or EventRouter.port, function() sock:close() end)
end

return EventRouter