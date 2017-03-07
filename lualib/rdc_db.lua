local _M = {}

local httpc = require 'http.httpc'

httpc.dns()
httpc.timeout = 100

local conf = {
    host = "127.0.0.1",
    port = "8000",
    base_url = "/api/method/",
    header = {
        HDB_AutherizationCode = "AAAAAAAAAA"
    }
}

function _M.get(api, recvheader, header, content)
    local header = setmetatable(header or {}, { __index = conf.header })
    local host = conf.host..":"..conf.port
    local url = conf.base_url..api
    return httpc.request('GET', host, url, recvheader, header, content)
end

local function escape(s)
	return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

function _M.post(api, form, recvheader)
    local header = setmetatable({
		["content-type"] = "application/x-www-form-urlencoded"
	}, { __index=conf.header })
	local body = {}
	for k,v in pairs(form) do
		table.insert(body, string.format("%s=%s",escape(k),escape(v)))
	end

    local host = conf.host..":"..conf.port
    local url = conf.base_url..api

	return httpc.request("POST", host, url, recvheader, header, table.concat(body , "&"))
end

function _M.login(user, passwd)
    local respheader = {}
    local status, body = _M.get(conf.."login", respheader, {user=user, passwd=passwd})

    if status == 200 then
        return body
    end
    return nil, body
end

function _M.logout(user)
    return true
end
