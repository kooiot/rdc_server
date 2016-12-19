local skynet = require 'skynet'
local snax = require 'snax'

skynet.start(function()
	skynet.fork(function()
		print('got enet_server')
		local es = snax.queryservice('enet_server')
		print('got enet_server')
		es.req.ping()
	end)
end)
