local skynet = require "skynet"
local socket = require "socket"
local enet = require 'enet'

local _M = {}

function response.ping()
	print('PING from skynet')
	return true
end

local function create_enet(host, port)
	local host = enet.host_create(host..":"..port)
	assert(host)

	while true do
		local event = host:service(50)
		if event and event.type == "receive" then
			print("Get message: ", event.data, event.peer)
			print(event.peer:index())
			print(event.peer:state())
			event.peer:send(event.data)
		end
		skynet.sleep(0)
	end
end

function init(c)
	local host = c.host or "0.0.0.0"
	local port = c.port or "6789"
	skynet.fork(function()
		create_enet(host, port)
	end)
	skynet.error("Stream Server init ...")
end

function exit(...)
	skynet.error("Stream Server exit ...")
end
