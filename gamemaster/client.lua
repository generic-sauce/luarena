function new_clientmaster(networker, player_count, local_id)
	local clientmaster = require("game/mod").new(player_count, local_id)

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
