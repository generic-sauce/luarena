local enet = require "enet"

return function(server, port)
	if port == nil then
		port = "3842"
	end

	print("opening server at " .. port)

	server.clients = {}
	server.host = enet.host_create("localhost:" .. port)
	if server.host == nil then
		print("Failed to open server")
		os.exit(1)
	end

	function server:handle_event(event)
		if event.type == "connect" then
			print("client joined!")
			table.insert(server.clients, event.peer)
		elseif event.type == "receive" then
			print("received: " .. event.data)
		end
	end

	function server:update(dt)
		while true do
			local event = server.host:service(100)
			if event == nil then break end
			server:handle_event(event)
		end
	end

	return server
end
