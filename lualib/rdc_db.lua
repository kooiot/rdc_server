local json = require 'cjson'

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

local function escape(s)
	return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

function _M.get(api, recvheader, header, query, content)
    local query = query or {}
    local header = setmetatable(header or {}, { __index = conf.header })
    local host = conf.host..":"..conf.port
    local url = conf.base_url..api
    local q = {}
    for k,v in pairs(query) do
        table.insert(q, string.format("%s=%s",escape(k),escape(v)))
    end
    if #q then
        url = url..'?'..table.concat(q, '&')
    end

    return httpc.request('GET', host, url, recvheader, header, content)
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

function _M.post_json(api, data, recvheader)
    local header = setmetatable({
		["content-type"] = "application/json"
	}, { __index=conf.header })
	local body = json.encode(data)
    local host = conf.host..":"..conf.port
    local url = conf.base_url..api

	return httpc.request("POST", host, url, recvheader, header, body)
end

function _M.login(user, passwd)
    local respheader = {}
    local status, body = _M.get("login", respheader, nil, {user=user, passwd=passwd})

    if status == 200 then
        return body
    end
    return nil, body
end

function _M.logout(user)
    return true
end

function _M.list_devices(user)
    local respheader = {}
    local status, body = _M.get("list_devices", respheader, nil, {user=user})

    if status == 200 then
        return body
    end
    return nil, body
end

function _M.add_device(device)
    local respheader = {}
    local status, body = _M.post_json('add_device', device, respheader)
    print(status, body)
    return true
end

function _M.update_device_status(sn, status)
    local respheader = {}
    local status, body = _M.post_json('update_device_status', {sn=sn, status=status}, respheader)
    print(status, body)
    return true
end

return _M
