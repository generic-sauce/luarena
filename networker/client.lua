local enet = require "enet"

return function(event_handler, server_ip, server_port)
	local client = {}
	client.event_handler = event_handler

	if server_port == nil then
		server_port = "3842"
	end

	print("trying to connect to " .. server_ip .. ":" .. server_port)

	client.host = enet.host_create()
	client.server_host = client.host:connect(server_ip .. ":" .. server_port)

	function client:send_to_server(p)
		client.server_host:send(p)
	end

	function client:handle_events()
		while true do
			local event = client.host:service(100)

			if event == nil then break end

			if event.type == "connect" then
				if client.event_handler.on_connect ~= nil then
					client.event_handler:on_connect()
				end
			elseif event.type == "receive" then
				-- print("received: " .. event.data .. " from " .. tostring(event.peer))
				if client.event_handler.on_recv ~= nil then
					client.event_handler:on_recv(event.data)
				end
			else
				print("networker/client got strange event of type: " .. event.type)
			end
		end
	end

	return client
end
