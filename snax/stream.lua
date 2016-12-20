local skynet = require "skynet"
local socket = require "socket"
local enet = require 'enet'
local log = require 'utils.log'

local _M = {}

local device_streams = {} -- { dev_id -> { chn -> user { id, chn } } }
local user_streams = {} -- { user_id -> { chn -> dev { id, chn } } }
local streams = {}

function response.ping()
	log.debug('PING from skynet')
	return true
end

function response.add_pair(key, dev, user)
	log.debug('Binding Pair ', user.id, user.chn, dev.id, dev.chn)

	assert(dev and user)
	assert(dev.id and dev.chn)
	assert(user.id and user.chn)

	device_streams[dev.id] = device_streams[dev.id] or {}
	local ds = device_streams[dev.id]
	user_streams[user.id] = user_streams[user.id] or {}
	local us = user_streams[user.id]

	if ds[dev.chn] then
		return nil, "Current Device Channel has been used by "..table.concat(ds[dev.chn], ':')
	end
	if us[user.chn] then
		return nil, "Current User Channel has been used by "..table.concat(us[dev.chn], ':')
	end

	streams[key] = { user = user, dev = dev, info = {time =os.time()} }
	ds[dev.chn] = { user.id, user.chn }
	us[user.chn] = { dev.id, dev.chn }

	return true
end

function response.remove_pair(key)
	assert(key)
	if not streams[key] then
		return nil, "Stream "..key.." does not exists"
	end

	local user = streams[key].user
	local dev = streams[key].dev
	local ds = device_streams[dev.id]
	local us = user_streams[user.id]
	if ds then
		ds[dev.chn] = nil
	end
	if us then
		us[user.chn] = nil
	end
	streams[key] = nil
	return true
end

function response.list_pairs()
	return streams
end

function response.clear_pairs()
	local list = {}
	for k, v in pairs(streams) do
		list[#list+1] = key
	end
	for _, key in ipairs(list) do
		reponse.remove_pair(key)
	end
	return true
end

local function create_enet(host, port)
	-- address, peer_count=64, channel_count=1, in_bandwidth=0, out_bandwidth=0
	local host = enet.host_create(host..":"..port, 128, 16)
	assert(host)

	while true do
		local event = host:service(50)
		if event and event.type == "receive" then
			log.debug("STREAM:Got message", event.data, event.peer, event.channel, event.peer:index(), event.peer:state())
			event.peer:send(event.data, event.channel)
		end
		if event and event.type == 'connect' then
			log.debug("STREAM:Connect peer data", event.data)
		end
		if event and event.type == 'disconnect' then
			log.debug("STREAM:Disconnect peer data", event.data)
		end
		skynet.sleep(0)
	end
end

function init(c)
	local host = c.host or "0.0.0.0"
	local port = c.port or "6789"
	skynet.fork(function()
		create_enet(host, port)
	end)
	skynet.error("Stream Server init ...")
end

function exit(...)
	skynet.error("Stream Server exit ...")
end
