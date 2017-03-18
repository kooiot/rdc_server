local skynet = require "skynet"
local cjson = require 'cjson'
local rdc_db = require "rdc_db"
local event_queue = require 'event_queue'

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
}

local gate
local userid, subid
local queue = event_queue()

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
    queue.abort()
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	skynet.error(string.format("AFK"))
end

function CMD.send_msg(msg)
    return queue.push(msg, 100)
end

local MSG = {}

function MSG.list_devices(user, data)
    return rdc_db.list_devices(user)
end

-- TImeout in second
function MSG.poll_msg(user, timeout)
    return queue.pop(timeout, 500)
end

skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	skynet.dispatch("client", function(_,_, msg)
		-- the simple echo service
		--skynet.sleep(100)	-- sleep a while
		--skynet.ret(msg)
        local msg = cjson.decode(msg)
        if msg then
            assert(msg.user == userid)
            if MSG[msg.cmd] then
                skynet.ret(MSG[msg.cmd](msg.user, msg.data))
            else
                skynet.ret("There is no command "..msg.cmd)
            end
        end
	end)
end)
