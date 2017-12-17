local enet = require "enet"

return function(client, server_ip, server_port)
	if server_port == nil then
		server_port = "3842"
	end

	print("trying to connect to " .. server_ip .. ":" .. server_port)

	client.id = -1
	client.host = enet.host_create()
	client.server_host = client.host:connect(server_ip .. ":" .. server_port)

	function client:handle_event(event)
		if event.type == "receive" then
			if client.id == -1 then
				client.id = tonumber(event.data)
				print("I'm client with id " .. client.id)
			end
		end
	end

	function client:update(dt)
		while true do
			local event = client.host:service(100)
			if event == nil then break end
			client:handle_event(event)
		end
	end

	return client
end
