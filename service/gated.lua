local msgserver = require "msg_server"
local crypt = require "skynet.crypt"
local skynet = require "skynet"

local loginservice = tonumber(...)

local server = {}
local users = {}
local username_map = {}
local internal_id = 0

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function server.login_handler(uid, secret)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
	local username = msgserver.username(uid, id, servername)

	-- you can use a pool to alloc new agent
	local agent = skynet.newservice "agent"
	local u = {
		username = username,
		agent = agent,
		uid = uid,
		subid = id,
	}

	-- trash subid (no used)
	skynet.call(agent, "lua", "login", uid, id, secret)

	users[uid] = u
	username_map[username] = u

	msgserver.login(username, secret)

	-- you should return unique subid
	return id
end

-- call by agent
function server.logout_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		msgserver.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
		skynet.call(loginservice, "lua", "logout",uid, subid)
	end
end

-- call by login server
function server.kick_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

-- call by self (when socket connect)
function server.connect_handler(username, fd)
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "connect", username, fd)
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg, sz)
	local u = username_map[username]
	agent = assert(u.agent, "There is no agent for "..username)
	skynet.redirect(u.agent, u.subid, "client", 1, msg, sz)
end

-- call by self (when gate open)
function server.register_handler(name)
	servername = name
	skynet.error("login serverice", string.format("[%08x]", loginservice))
	skynet.call(loginservice, "lua", "register_gate", servername, skynet.self())
end

local CMD = {}
CMD.find_user = function(user)
	local u = users[user]
	if u then
		return u.agent
	end
	return nil, "No user agent for "..user
end

-- called for skynet.call(gate, "lua", "xxx")
function server.command_handler(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(...)
end

msgserver.start(server)

