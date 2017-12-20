local gamemaster_mod = require('gamemaster/mod')

function new_clientmaster(networker, chars, local_id)
	local clientmaster = require("game/mod").new(chars, local_id)

	clientmaster.avg_backtrack = nil

	clientmaster.networker = networker
	networker.event_handler = clientmaster

	function clientmaster:send(p)
		self.networker:send_to_server(p)
	end

	function clientmaster:on_recv(p)
		if p.tag == "inputs" then
			local current_backtrack = #self.frame_history - p.frame_id + 1 -- may be negative
			self.avg_backtrack = gamemaster_mod.calc_avg_backtrack(self.avg_backtrack, current_backtrack)
			self:apply_input_changes(p.inputs, p.player_id, p.frame_id)
		elseif p.tag == "avg_backtrack" then
			if p.avg_backtrack ~= nil and self.avg_backtrack ~= nil then
				self.start_time = self.start_time + FRAME_DURATION * (self.avg_backtrack - p.avg_backtrack)/2
				self.avg_backtrack = nil
			end
		else
			print("clientmaster received packet of strange tag: " .. tostring(p.tag))
		end
	end

	print("client - gamemaster alive!")
	return clientmaster
end

return new_clientmaster
