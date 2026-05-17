local EventRouter = {
	port = 9001,
	_handlers = {},
	_socket = nil,
}

local function dispatch(namespace, action, value)
	local bucket = EventRouter._handlers[namespace]
	if not bucket then
		return
	end
	for _, handler in ipairs(bucket[action] or {}) do
		handler(action, value)
	end
	for _, handler in ipairs(bucket["*"] or {}) do
		handler(action, value)
	end
end

function EventRouter.on(namespace, action, handler)
	if type(action) == "function" then
		handler, action = action, "*"
	end
	EventRouter._handlers[namespace] = EventRouter._handlers[namespace] or {}
	local list = EventRouter._handlers[namespace][action] or {}
	list[#list + 1] = handler
	EventRouter._handlers[namespace][action] = list
	return EventRouter
end

EventRouter.register = EventRouter.on

function EventRouter.start(port)
	if port then
		EventRouter.port = port
	end
	EventRouter._socket = hs.socket.udp.new(function(data, _addr)
		local namespace, action, value = data:match("^(%S+)%s+(%S+)%s*(.*)")
		if namespace then
			dispatch(namespace, action, value ~= "" and value or nil)
		end
		EventRouter._socket:receive()
	end)
	EventRouter._socket:listen(EventRouter.port):receive()
	return EventRouter
end

function EventRouter.send(namespace, action, value, port, host)
	local message = namespace .. " " .. action .. (value and (" " .. value) or "")
	local sock = hs.socket.udp.new()
	sock:send(message, host or "127.0.0.1", port or EventRouter.port, function()
		sock:close()
	end)
end

return EventRouter
