require('json')

function new_servermaster(networker)
	local servermaster = require("game/mod").new(#networker.clients + 1, 1)

	servermaster.networker = networker
	networker.event_handler = servermaster

	function servermaster:send(p)
		self.networker:broadcast_packet(p)
	end

	function servermaster:on_recv(p)
		local t = json.decode(p)
		self:apply_input_changes(t.inputs, t.player_id, t.frame_id)

		-- packet forwarding
		for key, client in pairs(self.networker.clients) do
			if key + 1 ~= player_id then
				client:send(p)
			end
		end
	end

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
