local dev = require("dev")

local enet = require "enet"
require "json"

return function(event_handler, server_ip, server_port)
	local client = {}
	client.event_handler = event_handler

	if server_port == nil then
		server_port = "3842"
	end

	dev.debug("trying to connect to " .. server_ip .. ":" .. server_port, {"network"})

	client.host = enet.host_create()
	client.server_host = client.host:connect(server_ip .. ":" .. server_port)

	function client:send_to_server(p)
		local packet = json.encode(p)
		self.server_host:send(packet)
	end

	function client:handle_events()
		local received_packets = {}

		while true do
			local event = self.host:service()

			if event == nil then break end

			if event.type == "connect" then
				if self.event_handler.on_connect then
					self.event_handler:on_connect()
				end
			elseif event.type == "receive" then
				table.insert(received_packets, json.decode(event.data))
			else
				print("networker/client got strange event of type: " .. event.type)
			end
		end

		if #received_packets > 0 then
			dev.debug("networker/client: received " .. tostring(#received_packets) .. " packets", {"network"})
			if self.event_handler.on_recv then
				self.event_handler:on_recv(received_packets)
			end
		end

	end

	return client
end
