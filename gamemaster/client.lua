require("json")

function new_clientmaster(networker, player_count, local_id)
	local clientmaster = require("game/mod").new(player_count, local_id)

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	function clientmaster:send(p)
		self.networker:send_to_server(p)
	end

	function clientmaster:on_recv(p)
		local t = json.decode(p)
		self:apply_input_changes(t.inputs, t.player_id, t.frame_id)
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
