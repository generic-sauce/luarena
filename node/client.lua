local enet = require "enet"

return function(client, server_ip, server_port)
	if server_port == nil then
		server_port = "3842"
	end

	print("trying to connect to " .. server_ip .. ":" .. server_port)

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
