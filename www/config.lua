--
-- This is a LWF Application Config file
-- 
--
return {
	static = 'static',
	session={
		key		= 'lwfsession', -- default is lwfsession
		pass_salt	= '8C7f8lProgw3U4IvVyDqk38bD0HAD8hBBfHZRMRF',
		salt		= 'tdzd77zTw3aHW8IqZgQteXUG3s5kFMQZQf2ODSXZ',
	},
	i18n = true,

	auth = "simple",
	--[[
	auth = {
		name = 'mysql',
		password = '19840310',
	},
	]]--

	debug={
		on = true,
		to = "response", -- "logger"
	},

	subapps={
	},
}
