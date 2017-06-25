local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register

local command = {}
local db_map = {}

function command.AUTH(server, user, passwd)
	local db = db_map[server]
	if not db then
		return nil, "User auth database does not exists for server "..server
	end
    return db:login(user, passwd)
end

function command.add_db(server, module, ...)
	--local rdc_db = require "rdc_db"
	local loaded, db = pcall(require, module)
	if not loaded then
		return nil, db
	end
	db_map[server] = db:new(...)
	return true
end

skynet.start(function()
    -- Connect to DB?
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[string.upper(cmd)]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register("AUTH")
end)
