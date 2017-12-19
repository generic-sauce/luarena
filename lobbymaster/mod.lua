-- create a network node (either server or client) by parsing the CLI args

local lobby_mod = {}

function usage()
	print("usage:\n\tlove . server <character> [<port>]\n\tlove . client <character> <server_ip> [<server_port>]")
	os.exit(1)
end

function new_node()
	local node = {}
	function node:draw() end
	return node
end

function new_server(char, port)
	return require("lobbymaster/server")(new_node(), char, port)
end

function new_client(char, server_ip, server_port)
	return require("lobbymaster/client")(new_node(), char, server_ip, server_port)
end

function lobby_mod.create_lobby_master()
	if arg[2] == "server" then
		return new_server(arg[3], arg[4])
	elseif arg[2] == "client" then
		return new_client(arg[3], arg[4], arg[5])
	else
		usage()
	end
end

return lobby_mod
