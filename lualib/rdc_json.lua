local _M = {}

_M.login = {
    request = {
        { name = 'user', type = 'string' },
        { name = 'passwd', type = 'string' }
    },
    response = {
        { name = 'session', type = 'string' }
    }
}

_M.logout = {
    request = {},
    response = {}
}

_M.net_peer = {
    { name = "host", type = "string" },
    { name = "port", type = "number" }
}

_M.net = {
    { name = "local", type = "net_peer" },
    { name = "remote", type = "net_peer" },
    { name = "protocol", type = "select", options = "tcp,udp,http" }
}

_M.serial = {
    { name = "baudrate", type = "number" },
    { name = "bytesize", type = "select", options = "5,6,7,8" },
    { name = "parity", type= 'select', options = "none,odd,event,mark,spce" },
    { name = "stopbits", type = "select", options = "one,one_five,two" },
    { name = 'flowcontrol', type = 'select', options = 'none,software,hardware' }
}

_M.plugin = {
    { name = "plugin", type = 'string' },
    { name = 'config', type = 'string' }
}

_M.packet = {
    { name = 'session', type = 'string' }
}

_M.create = {
    request = {
        { name = 'device', type = 'string' },
        { name = 'channel', type = 'number' },
        { name = 'type', type = 'select', options = 'net,serial,plugin,test' },
        { name = 'data', type = 'json' },
    },
    response = {
        { name = 'result', type = 'number' },
        { name = 'device_channel', type = 'number' },
        { name = 'message', type = 'string' }
    }
}

_M.destroy = {
    request = {
        { name = 'device', type = 'string' },
        { name = 'channel', type = 'number' }
    },
    response = {
        { name = 'result', type = 'number' },
        { name = 'message', type = 'string' }
    }
}

_M.device = {
    { name = 'sn', type = 'string' },
    { name = 'name', type = 'string' },
    { name = 'description', type = 'string' },
    { name = 'creation', type = 'datetime' },
    { name = 'validation', type = 'datetime' }
}

_M.list_devices = {
    request = {
        { name = 'filter', type = 'string' }
    },
    response = {
        { name = 'devices', type = 'array', options = 'device' }
    }
}

_M.stream = {
    { name = 'device', type = 'string' },
    { name = 'device_channel', type = 'number' },
    { name = 'user', type = 'string' },
    { name = 'user_channel', type = 'number' }
}

_M.list_streams = {
    request = {},
    response = {
        { name = 'streams', type = 'array', options = 'stream' }
    }
}


return _M
