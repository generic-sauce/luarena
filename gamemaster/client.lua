function new_clientmaster(networker)
	local clientmaster = {}

	networker.event_handler = clientmaster

	clientmaster.game = require("game/mod").new()

	function clientmaster:update(dt)
		clientmaster.game:update(dt)
	end

	function clientmaster:draw()
		clientmaster.game:draw()
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
