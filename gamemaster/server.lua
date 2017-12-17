function new_servermaster(networker)
	local servermaster = require("game/mod").new(#networker.clients + 1, 1)

	servermaster.networker = networker
	networker.event_handler = servermaster

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
