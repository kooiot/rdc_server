local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local rdc_db = require "rdc_db"

local arg = table.pack(...)
assert(arg.n == 1)
local server_name = arg[1]

local command = {}

function command.AUTH(user, passwd)
    assert(rdc_db.login(user, passwd))
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
	skynet.register(".auth."..server_name)
end)
