local skynet = require "skynet"
local cjson = require 'cjson'
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local gate
local userid, subid, servername
local client_username
local client_fd
local session_id = 1
local response_callback_map = {}
local request_id = 1
local request_co_map = {}
local request_result = {}
local REQUEST = {}

local host = sprotoloader.load(1):host "package"
local create_request = host:attach(sprotoloader.load(2))

function REQUEST.handshake()
	--return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
	return { msg = "Welcome to Remtoe Device Connector Cloud." }
end

function REQUEST.list_devices(args)
	if not servername then
		servername = skynet.call(gate, "lua", "server_name")
	end
	return skynet.call("APIMGR", "lua", "list_devices", servername, args.user)
end

function REQUEST.create(args)
	local dev_agent = skynet.call(gate, "lua", "find_user", args.device)
	if not dev_agent then
		return {
			result = false,
			msg = "Device "..args.device.." is not online"
		}
	end
	local id = request_id
	request_id = request_id + 1
	assert(request_co_map[id] == nil)

	request_co_map[id] = coroutine.running()
	skynet.call(dev_agent, "lua", "forward_request", id, "create", args)
	skynet.wait()

	local r = request_result[id]
	request_result[id] = nil
	request_co_map[id] = nil
	return r
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

local function send_request(name, args, response_callback)
	send_package(create_request(name, args, session_id))
	response_callback_map[session_id] = response_callback
	session_id = session_id + 1
end

local function handle_response(session, args)
	--print(session, args)
	local callback = response_callback_map[session]
	if not callback then
		skynet.error("Callback function missing for session: ", session)
	else
		callback(args)
	end
	response_callback_map[session] = nil
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
			-- error "This example doesn't support request client"
			handle_response(...)
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

function CMD.connect(source, username, fd)
	-- slot 1,2 set at main.lua
	client_username = username
	client_fd = fd
end

--- Called by other peer
function CMD.forward_request(source, rid, request, params)
	return send_request(request, params, function(args)
		skynet.call(source, "lua", "forward_result", rid, args)
	end)
end

--- Called when create request finished
function CMD.forward_result(source, rid, args)
	local co = request_co_map[rid]
	if co then
		request_result[rid] = args
		skynet.wakeup(co)
	else
		log.warning("No waiting coroutine for response")
	end
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
				send_request("heartbeat")
			end
			skynet.sleep(500)
		end
	end)
end)
