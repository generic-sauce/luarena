local enet = require "enet"

return function(server, port)
	function server:on_client_connects()
		print("client connected!")
	end

	server.networker = require("networker/server")(server, port)

	function server:broadcast_update_packet()
		function build_update_packet()
			return "u" .. tostring(#server.networker.clients)	-- currently the number of clients says it all
																-- "u" => update packet
		end

		server.networker:broadcast_packet(build_update_packet())
	end

	function server:go()
		server.networker:broadcast_packet("g")
		master = require("gamemaster/server")(server.networker)
	end

	function server:update(dt)
		server.networker:handle_events()

		if love.keyboard.isDown('g') then
			server:go()
		end
	end

	return server
end
