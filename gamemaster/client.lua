local packetizer_mod = require("packetizer")

function new_clientmaster(networker, player_count, local_id)
	local clientmaster = require("game/mod").new(player_count, local_id)

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	function clientmaster:send(p)
		self.networker:send_to_server(p)
	end

	function clientmaster:on_recv(p)
		local changed_inputs, player_id, frame_id = packetizer_mod.packet_to_inputs(p)
		self:apply_input_changes(changed_inputs, player_id, frame_id)
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
