local enet = require "enet"

return function(client, server_ip, server_port)
	client.id = nil
	client.client_count = nil

	function client:on_recv(p)
			local packet_type = p:sub(1, 1)
			local data = p:sub(2, -1)

			if packet_type == "u" then -- update packet
				if client.id == nil then
					client.id = tonumber(data)
					print("I'm client with id " .. client.id)
				end
				client.client_count = tonumber(data)
			elseif packet_type == "g" then -- go packet
				print("go!")
			else
				print("received strange packet: " .. p)
			end
	end

	client.networker = require("networker/client")(client, server_ip, server_port)

	function client:update(dt)
		client.networker:handle_events()
	end

	return client
end
