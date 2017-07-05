local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register

local command = {}
local api_map = {}

function command.auth(server, user, passwd)
	local api = api_map[server]
	if not api then
		return nil, "User auth api does not exists for server "..server
	end
    return api:login(user, passwd)
end

function command.list_devices(server, user)
	local api = api_map[server]
	return api:list_devices(user)
end

function command.add_api(server, module, ...)
	local loaded, api = pcall(require, module)
	if not loaded then
		return nil, api
	end
	api_map[server] = api:new(...)
	return true
end

skynet.start(function()
    -- Connect to DB?
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[string.lower(cmd)]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register("APIMGR")
end)
