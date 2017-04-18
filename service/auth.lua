local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local rdc_db = require "rdc_db"

local command = {}

function command.AUTH(server, user, passwd)
    return rdc_db.login(user, passwd)
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
