-- love

function love.load()
	function handle_cli()
		if arg[2] == "server" then
			return mk_server_main(arg[3])
		elseif arg[2] == "client" then
			return mk_client_main(arg[3], arg[4])
		else
			print("invalid command-line arguments!")
			os.exit(1)
		end
	end

	main = handle_cli()
end

function love.update(dt)
	main:update(dt)
end

function love.draw()
end

-- server / client

socket = require "socket"

function mk_server_main(port)
	if port == nil then
		port = "3842"
	end

	print("opening server at " .. port)

	local server = {}
	server.udp = socket.udp()
	server.udp:settimeout(0)
	server.udp:setsockname('127.0.0.1', tonumber(port))

	function server:update(dt)
		print(server.udp:receive())
	end

	return server
end

function mk_client_main(server_ip, server_port)
	if server_port == nil then
		server_port = "3842"
	end

	print("trying to connect to " .. server_ip .. ":" .. server_port)

	local client = {}

	client.udp = socket.udp()
	client.udp:settimeout(0)
	client.udp:setpeername(server_ip, tonumber(server_port))

	function client:update(dt)
		client.udp:send({x=2,y="wow"})
	end

	return client
end
