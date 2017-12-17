-- create a network node (either server or client) by parsing the CLI args

function new_node()
	local game_mod = require("game")

	local node = {}
	node.game = game_mod.new()

	function node:update(dt) node.game:update(dt) end
	function node:draw() node.game:draw() end

	return node
end

function new_server(port)
	return require("node/server")(new_node(), port)
end

function new_server(server_ip, server_port)
	return require("node/client")(new_node(), server_ip, server_port)
end

function parse_cli()
	if arg[2] == "server" then
		return new_server(arg[3])
	elseif arg[2] == "client" then
		return new_client(arg[3], arg[4])
	else
		print("invalid command-line arguments!")
		os.exit(1)
	end
end

return parse_cli
