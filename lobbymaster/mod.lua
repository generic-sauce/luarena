-- create a network node (either server or client) by parsing the CLI args

local lobby_mod = {}

function new_node()
	local node = {}
	function node:draw() end
	return node
end

function new_server(port)
	return require("lobbymaster/server")(new_node(), port)
end

function new_client(server_ip, server_port)
	return require("lobbymaster/client")(new_node(), server_ip, server_port)
end

function lobby_mod.create_lobby_master()
	if arg[2] == "server" then
		return new_server(arg[3])
	elseif arg[2] == "client" then
		return new_client(arg[3], arg[4])
	else
		print("invalid command-line arguments!")
		os.exit(1)
	end
end

return lobby_mod
