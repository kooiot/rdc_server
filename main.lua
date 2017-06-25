local skynet = require "skynet"
local snax = require "skynet.snax"
local sprotoloader = require "sprotoloader"

local is_windows = package.config:sub(1,1) == '\\'

skynet.start(function()
	skynet.error("Skynet RDC Server Start")
	skynet.uniqueservice("protoloader")
	if not is_windows and not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",7000)
	skynet.newservice("cfg")
--	local starter = snax.uniqueservice("starter")

	local loginserver = skynet.newservice("logind")

    local apimgr = skynet.newservice("apimgr")
	skynet.call(apimgr, "lua", "add_api", "sample", "frappe_api")

	local gate = skynet.newservice("gated", loginserver)

	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})

	skynet.newservice("adminweb", "0.0.0.0", 8090)
	skynet.exit()
end)
