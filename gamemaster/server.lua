local gamemaster_mod = require('gamemaster/mod')

function new_servermaster(chars, networker)
	local servermaster = require("game/mod").new(chars, 1)

	servermaster.avg_backtrack_list = {}

	servermaster.networker = networker
	networker.event_handler = servermaster

	function servermaster:send(p)
		self.networker:broadcast_packet(p)
	end

	function servermaster:on_recv(p)
		if p.tag == "inputs" then
			local current_backtrack = #self.frame_history - p.frame_id + 1 -- may be negative
			self.avg_backtrack_list[p.player_id - 1] = gamemaster_mod.calc_avg_backtrack(self.avg_backtrack_list[p.player_id - 1], current_backtrack)
			self:apply_input_changes(p.inputs, p.player_id, p.frame_id)

			-- packet forwarding
			for key, client in pairs(self.networker.clients) do
				if key + 1 ~= p.player_id then
					client:send(json.encode(p))
				end
			end
		else
			print("servermaster received packet of strange tag: " .. tostring(p.tag))
		end
	end

	function servermaster:send_avg_update_packet()
		for i, value in pairs(self.avg_backtrack_list) do
			self.networker.clients[i]:send(json.encode({
				tag = "avg_backtrack",
				avg_backtrack = value
			}))
			self.avg_backtrack_list[i] = nil
		end
	end

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
