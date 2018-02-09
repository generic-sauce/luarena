local dev = require("dev")

local backtrack_balancer_mod = require('gamemaster/backtrack_balancer')

function new_clientmaster(networker, chars, local_id)
	local clientmaster = require("game/mod").new(chars, local_id)

	clientmaster.balancer = backtrack_balancer_mod.new()

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	function clientmaster:send(p)
		self.networker:send_to_server(p)
	end

	function clientmaster:on_recv(packets)
		local input_packets = {}

		for _, p in pairs(packets) do
			if p.tag == "inputs" then
				table.insert(input_packets, p)
				local current_backtrack = #self.frame_history - p.frame_id + 1 -- may be negative
				self.balancer:push_value(current_backtrack)
			elseif p.tag == "avg_backtrack" then
				if p.avg_backtrack ~= nil then
					local avg = self.balancer:pop_avg()
					if avg ~= nil then
						local old_time = self.start_time
						self.start_time = self.start_time + FRAME_DURATION * (avg - p.avg_backtrack)/2
						dev.debug("start_time: " .. tostring(old_time) .. " -> " .. tostring(self.start_time), {"network", "backtrack"})
					end
				end
			else
				print("clientmaster received packet of strange tag: " .. tostring(p.tag))
			end
		end

		if #input_packets > 0 then
			self:apply_input_changes(input_packets)
		end
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster