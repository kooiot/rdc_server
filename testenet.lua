local skynet = require 'skynet'
local snax = require 'snax'
local log = require 'utils.log'

local function test()
	local enet = require 'enet'
	assert(enet, 'Require ENet module')

	local host = enet.host_create()
	local server = host:connect("localhost:6789", 16, 123456)

	local done = false
	local count = 0
	while not done do
		local event = host:service(100)
		if event then
			if event.type == "connect" then
				log.debug("CLIENT:Connected to", event.peer)
				event.peer:send("hello world")
				event.peer:send("hello world", 1)
			elseif event.type == "receive" then
				log.debug("CLIENT:Got message", event.data, event.peer, event.channel)
				count = count + 1
				if count == 2 then
					done = true
				end
			end
		end
	end

	server:disconnect(123456)
	host:flush()
end

skynet.start(function()
	skynet.fork(function()
		local es = snax.queryservice('stream')
		es.req.ping()
	end)
	skynet.fork(test)
end)
