function new_clientmaster(networker, player_count, local_id)
	local clientmaster = require("game/mod").new(player_count, local_id)

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	function clientmaster:send(p)
		clientmaster.networker:send_to_server(p)
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
