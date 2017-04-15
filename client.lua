if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;rdc/lualib/?.lua"

local socket = require "clientsocket"
local crypt = require "crypt"
local login = require("client.login"):new("127.0.0.1", 8001)

local token = {
	server = 'sample',
	user = 'changch84@163.com',
	passwd = 'pa88word'
}

local r, subid, secret = assert(login:login(token.server, token.user, token.passwd))

print("login ok, subid=", subid)

----- connect to game server
local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end


local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

local text = "echo"
local index = 1

print("connect")
local fd = assert(socket.connect("127.0.0.1", 8888))
local readpackage = login.unpacker(fd, unpack_package)

local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

print(readpackage())

print("disconnect")
socket.close(fd)

index = index + 1

print("connect again")
fd = assert(socket.connect("127.0.0.1", 8888))
readpackage = login.unpacker(fd, unpack_package)

local gate_client = require 'client.gate':new(fd)

local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

print(readpackage())

gate_client:send_request("handshake")
while true do
	gate_client:dispatch_package()
end

print("disconnect")
socket.close(fd)

