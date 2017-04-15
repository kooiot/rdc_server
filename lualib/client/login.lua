local socket = require "clientsocket"
local crypt = require "crypt"
local class = require "middleclass"

local loginclass = class("LoginClass")

local function writeline(fd, text)
	socket.send(fd, text .. "\n")
end

local function unpack_line(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

local function encode_token(token)
	return string.format("%s@%s:%s",
	crypt.base64encode(token.user),
	crypt.base64encode(token.server),
	crypt.base64encode(token.passwd))
end

local function unpacker(fd, f)
	local last = ""

	local function unpack_f(fd, f)
		local fd = fd
		local function try_recv(fd, last)
			local result
			result, last = f(last)
			if result then
				return result, last
			end
			local r = socket.recv(fd)
			if not r then
				return nil, last
			end
			if r == "" then
				error "Server closed"
			end
			return f(last .. r)
		end

		return function()
			while true do
				local result
				result, last = try_recv(fd, last)
				if result then
					return result
				end
				socket.usleep(100)
			end
		end
	end

	return unpack_f(fd, f)
end



local function do_login(ip, port, server, user, passwd)
	local fd = assert(socket.connect(ip, port))

	local readline = unpacker(fd, unpack_line)

	local challenge = crypt.base64decode(readline())

	local clientkey = crypt.randomkey()
	writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
	local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

	print("sceret is ", crypt.hexencode(secret))

	local hmac = crypt.hmac64(challenge, secret)
	writeline(fd, crypt.base64encode(hmac))

	local token = {
		server = server,
		user = user,
		passwd = passwd, 
	}

	local etoken = crypt.desencode(secret, encode_token(token))
	local b = crypt.base64encode(etoken)
	writeline(fd, crypt.base64encode(etoken))

	local result = readline()
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200, result)
	socket.close(fd)

	local subid = crypt.base64decode(string.sub(result, 5))

	print("login ok, subid=", subid)

	return subid, secret
end


function loginclass:initialize(ip, port)
	self._ip = ip
	self._port = port
	self.unpacker = unpacker
end

function loginclass:login(server, user, passwd)
	return pcall(do_login, self._ip, self._port, server, user, passwd)
end

return loginclass
