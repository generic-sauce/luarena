local backtrack_balancer_mod = require('gamemaster/backtrack_balancer')

function new_servermaster(chars, networker, seed)
	assert(seed)

	local servermaster = require("game/mod").new(chars, 1, seed)

	servermaster.balancer_list = {}
	for _=1, #chars do
		table.insert(servermaster.balancer_list, backtrack_balancer_mod.new())
	end

	servermaster.networker = networker
	networker.event_handler = servermaster

	function servermaster:send(p)
		self.networker:broadcast_packet(p)
	end

	function servermaster:on_recv(packets)
		local input_packets = {}

		for _, p in pairs(packets) do
			if p.tag == "inputs" then
				table.insert(input_packets, p)
				local current_backtrack = self.frame_counter - p.frame_id + 1
				self.balancer_list[p.player_id - 1]:push_value(current_backtrack)
			else
				print("servermaster received packet of strange tag: " .. tostring(p.tag))
			end
		end

		if #input_packets > 0 then
			self:apply_input_changes(input_packets)
		end

		-- packet forwarding
		for _, p in pairs(packets) do
			for key, client in pairs(self.networker.clients) do
				if key + 1 ~= p.player_id then
					client:send(json.encode(p))
				end
			end
		end
	end

	function servermaster:gamemaster_update()
		if self.frame_counter % BACKTRACK_BALANCE_INTERVAL then
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
