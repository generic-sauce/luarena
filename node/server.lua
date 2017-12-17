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

	function server:broadcast_packet(p)
		for _, client in pairs(server.clients) do
			client:send(p)
		end
	end

	function server:broadcast_update_packet()
		function build_update_packet()
			return "u" .. tostring(#server.clients) -- currently the number of clients says it all
			-- "u" => update packet
		end

		server:broadcast_packet(build_update_packet())
	end

	function server:handle_event(event)
		if event.type == "connect" then
			print("client joined!")
			table.insert(server.clients, event.peer)
			server:broadcast_update_packet()
		elseif event.type == "receive" then
			print("received: " .. event.data)
		end
	end

	function server:go()
		server:broadcast_packet("g")
		print("go!")
	end

	function server:update(dt)
		while true do
			local event = server.host:service(100)
			if event == nil then break end
			server:handle_event(event)
		end

		if love.keyboard.isDown('g') then
			server:go()
		end
	end

	return server
end
