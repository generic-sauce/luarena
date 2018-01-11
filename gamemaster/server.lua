local backtrack_balancer_mod = require('gamemaster/backtrack_balancer')

function new_servermaster(chars, networker)
	local servermaster = require("game/mod").new(chars, 1)

	servermaster.balancer_list = {}
	for _=1, #chars do
		table.insert(servermaster.balancer_list, backtrack_balancer_mod.new())
	end

	servermaster.networker = networker
	networker.event_handler = servermaster

	function servermaster:send(p)
		self.networker:broadcast_packet(p)
	end

	function servermaster:on_recv(p)
		if p.tag == "inputs" then
			local current_backtrack = #self.frame_history - p.frame_id + 1
			self.balancer_list[p.player_id - 1]:push_value(current_backtrack)
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

	function servermaster:gamemaster_update()
		if #self.frame_history % BACKTRACK_BALANCE_INTERVAL then
			for i, balancer in pairs(self.balancer_list) do
				local avg = balancer:pop_avg()
				if avg then
					self.networker.clients[i]:send(json.encode({
						tag = "avg_backtrack",
						avg_backtrack = avg
					}))
				end
			end
		end
	end

	print("server - gamemaster alive!")
	return servermaster
end

return new_servermaster
