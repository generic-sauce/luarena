local enet = require "enet"

return function(event_handler, port)
	local server = {}
	server.event_handler = event_handler

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
		for _, client in pairs(self.clients) do
			-- print("sending '" .. p .. "' to client " .. tostring(client))
			client:send(p)
		end
	end

	function server:handle_events()
		while true do
			local event = self.host:service(100)

			if event == nil then break end

			if event.type == "connect" then
				table.insert(self.clients, event.peer)
				if self.event_handler.on_client_connects ~= nil then
					self.event_handler:on_client_connects()
				end
			elseif event.type == "receive" then
				if self.event_handler.on_recv ~= nil then
					self.event_handler:on_recv(event.data)
				end
			else
				print("networker/server got strange event of type: " .. event.type)
			end
		end
	end

	return server
end
