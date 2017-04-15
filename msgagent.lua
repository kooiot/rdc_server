local skynet = require "skynet"
local cjson = require 'cjson'
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local rdc_db = require "rdc_db"

local gate
local userid, subid
local client_fd
local REQUEST = {}

local host = sprotoloader.load(1):host "package"
local send_request = host:attach(sprotoloader.load(2))

function REQUEST.list_devices(user, data)
    return rdc_db.list_devices(user)
end

-- TImeout in second
function REQUEST.poll_msg(user, timeout)
end

function REQUEST.handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

local function request(name, args, response)
	local f = assert(REQUEST[name], "No request handler for "..name)
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

local CMD = {}

function CMD.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	-- you may load user data from database
end

local function logout()
	if gate then
		skynet.call(gate, "lua", "logout", userid, subid)
	end
	skynet.exit()
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	client_fd = nil
	skynet.error(string.format("AFK"))
end

function CMD.connect(source, fd)
	-- slot 1,2 set at main.lua
	client_fd = fd
end


skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)
	skynet.fork(function()
		while true do
			if client_fd then
				print('sending hearbeat', client_fd)
				send_package(send_request("heartbeat"))
			end
			skynet.sleep(500)
		end
	end)
end)
