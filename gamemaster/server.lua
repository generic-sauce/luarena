local packetizer_mod = require("packetizer")

function new_servermaster(networker)
	local servermaster = require("game/mod").new(#networker.clients + 1, 1)

	servermaster.networker = networker
	networker.event_handler = servermaster

	function servermaster:send(p)
		servermaster.networker:broadcast_packet(p)
	end

	function servermaster:on_recv(p)
		local changed_inputs, player_id, frame_id = packetizer_mod.packet_to_inputs(p)
		servermaster:apply_input_changes(changed_inputs, player_id, frame_id)

		-- packet forwarding
		for key, client in pairs(servermaster.networker.clients) do
			if key + 1 ~= player_id then
				client:send(p)
			end
		end
	end

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
