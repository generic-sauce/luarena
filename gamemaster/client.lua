function new_clientmaster(networker, chars, local_id, start_time)
	local clientmaster = require("game/mod").new(chars, local_id, start_time)

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	function clientmaster:send(p)
		self.networker:send_to_server(p)
	end

	function clientmaster:on_recv(p)
		self:apply_input_changes(p.inputs, p.player_id, p.frame_id)
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
