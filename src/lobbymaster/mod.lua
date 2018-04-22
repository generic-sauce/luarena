-- create a network node (either server or client) by parsing the CLI args

local lobby_mod = {}

function usage_text()
	return "usage:\n\tserver <character> [<port>]\n\tclient <character> <server_ip> [<server_port>]"
end

function usage()
	print(usage_text())
	os.exit(1)
end

function new_node()
	local node = {}
	function node:draw() end
	return node
end

local function new_server(char, port)
	return require("lobbymaster/server")(new_node(), char, port)
end

local function new_client(char, server_ip, server_port)
	return require("lobbymaster/client")(new_node(), char, server_ip, server_port)
end

function lobby_mod.create_lobby_master_by_args(args)
	if args[1] == "server" then
		return new_server(args[2], args[3])
	elseif args[1] == "client" then
		return new_client(args[2], args[3], args[4])
	else
		usage()
	end
end

function lobby_mod.create_lobby_master()
	love.window.setMode(800, 600, {resizable=true})

	if arg[2] == nil then
		return require('initmaster')
	else
		local args = {}
		local c = 2

		while arg[c] do
			table.insert(args, arg[c])
			c = c + 1
		end

		return lobby_mod.create_lobby_master_by_args(args)
	end
end

return lobby_mod
