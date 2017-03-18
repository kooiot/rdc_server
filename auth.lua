local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local db = {}
local server_name

local command = {}

function command.AUTH(key)
	return db[key]
end

function command.SET(key, value)
	local last = db[key]
	db[key] = value
	return last
end

skynet.start(function(server)
    server_name = server
    -- Connect to DB?
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[string.upper(cmd)]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register(".auth."..server_name)
end)
