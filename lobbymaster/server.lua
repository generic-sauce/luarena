local enet = require "enet"

return function(server, port)
	function server:on_client_connects()
		print("client connected!")
		self:broadcast_update_packet()
	end

	server.networker = require("networker/server")(server, port)

	function server:broadcast_update_packet()
		function build_update_packet()
			return "u" .. tostring(#self.networker.clients)	-- currently the number of clients says it all
															-- "u" => update packet
		end

		self.networker:broadcast_packet(build_update_packet())
	end

	function server:go()
		self.networker:broadcast_packet("g")
		master = require("gamemaster/server")(self.networker)
	end

	function server:update(dt)
		self.networker:handle_events()

		if love.keyboard.isDown('g') then
			self:go()
		end
	end

	return server
end
