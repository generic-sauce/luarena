function new_servermaster(networker)
	local servermaster = require("game/mod").new(#networker.clients + 1, 1)

	servermaster.networker = networker
	networker.event_handler = servermaster

	function servermaster:send(p)
		servermaster.networker:broadcast_packet(p)
	end

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
