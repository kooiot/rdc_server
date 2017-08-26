local skynet = require 'skynet.manager'
local snax = require 'skynet.snax'
local log = require 'utils.log'

local streams = {}
local cfg_def = {
	host = '0.0.0.0',
	port = 6123,
	stream = {
		base_port = 6789,
		count = 4,
	},
}

local function getcfg()
	local c = skynet.call("CFG", "lua", "get", "starter")
	return setmetatable(c or {}, { __index = cfg_def })
end

local function starter_start()
	cfg = getcfg()
	
	local host = cfg.host
	local count = cfg.stream.count
	local base_port = cfg.stream.base_port
	assert(count and base_port)

	for i = 1, count do
		local conf = {
			host = host,
			port = base_port + i - 1,
		}
		streams[i] = snax.newservice('stream', conf)	
	end
end

local function starter_close()
	for _, stream in ipairs(streams) do
		snax.kill(stream)
	end
	streams = {}
end

function response.ping(id)
	log.info('this is ping', id)
	return skynet.self()
end

function accept.stop()
	starter_close()
end

function init(...)
	skynet.error('Server Start...')
	skynet.fork(starter_start)
end

function exit(...)
	skynet.error('Server Stop...')
	starter_close()
end
