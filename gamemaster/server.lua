function new_servermaster(networker)
	local servermaster = {}

	networker.event_handler = servermaster

	servermaster.game = require("game/mod").new()

	function servermaster:update(dt)
		servermaster.game:update(dt)
	end

	function servermaster:draw()
		servermaster.game:draw()
	end

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
