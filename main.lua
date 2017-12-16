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

enet = require "enet"

function mk_server_main(port)
	if port == nil then
		port = "3842"
	end

	print("opening server at " .. port)

	local server = {}
	server.host = enet.host_create("localhost:" .. port)

	function server:update(dt)
		local event = server.host:service(100)

		if event == nil then return end

		if event.type == "connect" then
			print("connected!")
		elseif event.type == "receive" then
			print("received: " .. event.data)
		end
	end

	return server
end

function mk_client_main(server_ip, server_port)
	if server_port == nil then
		server_port = "3842"
	end

	print("trying to connect to " .. server_ip .. ":" .. server_port)

	local client = {}

	client.host = enet.host_create()
	client.server_host = client.host:connect(server_ip .. ":" .. server_port)

	function client:update(dt)
		local event = client.host:service(100)

		if event == nil then return end

		if event.type == "connect" then
			print("connected!")
			event.peer:send("nice!")
		end
	end

	return client
end
