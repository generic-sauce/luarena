function new_servermaster(chars, networker)
	local servermaster = require("game/mod").new(chars, 1)

	servermaster.networker = networker
	networker.event_handler = servermaster

	function servermaster:send(p)
		self.networker:broadcast_packet(p)
	end

	function servermaster:on_recv(p)
		self:apply_input_changes(p.inputs, p.player_id, p.frame_id)

		-- packet forwarding
		for key, client in pairs(self.networker.clients) do
			if key + 1 ~= p.player_id then
				client:send(json.encode(p))
			end
		end
	end

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
