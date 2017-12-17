function new_clientmaster(networker)
	local clientmaster = {}

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	clientmaster.game = require("game/mod").new()

	function clientmaster:update(dt)
		clientmaster.networker:handle_events()
		clientmaster.game:update(dt)
	end

	function clientmaster:draw()
		clientmaster.game:draw()
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
