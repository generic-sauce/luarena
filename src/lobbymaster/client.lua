local enet = require "enet"
require "json"

return function(client, char, server_ip, server_port)
	if char == nil then
		print("missing character!")
		usage()
	end

	client.local_id = nil
	client.chars = nil

	function client:on_recv(packets)
		for _, p in pairs(packets) do
			if p.tag == "chars" then
				if self.local_id == nil then
					self.local_id = #p.chars
					print("I'm client with id " .. self.local_id)
				end
				self.chars = p.chars
			elseif p.tag == "go" then
				print("go!")
				assert(p.seed)
				master = require("gamemaster/client")(self.networker, self.chars, self.local_id, p.seed)
			else
				print("received strange packet with tag: " .. p.tag)
			end
		end
	end


	function client:on_connect()
		self.networker:send_to_server({
			tag = "join",
			char = char
		})
	end

	client.networker = require("networker/client")(client, server_ip, server_port)

	function client:update(dt)
		self.networker:handle_events()
	end

	return client
end
