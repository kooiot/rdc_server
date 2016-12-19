local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

connect 1 {
	request {
		ip 0 : string
		port 1 : integer
		user 2 : string
		passwd 3 : string
	}
	response {
		result 0 : boolean
		msg 1 : string
	}
}

request 2 {
	request {
		request_type 0 : integer
		uri 1 : string
		content 2 : string
	}
	response {
		result 0 : boolean
		msg 1 : string
	}
}

subscribe 3 {
	request {
		uri 0 : string
		condition 1 : string
	}
	response {
		result 0 : boolean
		msg 1 : string
	}
}

unsubscribe 4 {
	request {
		uri 0 : string
	}
	response {
		result 0 : boolean
		msg 1 : string
	}
}

check_connection 5 {
	response {
		result 0 : boolean
		msg 1 : string
	}
}

getpid 6 {
	response {
		result 0 : integer 
	}
}

quit 99 {}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

callback 2 {
	request {
		.Header {
			src_type 0 : integer
			data_type 1 : integer
			event_type 2 : string
			event_source 3 : string
			src_uri 4 : string
			session_id 5 : string
			header_data 6 : string
		}
		header 0 : Header
		data 1 : string 
	}
}
]]

return proto
