local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

local REGEN_INTERVAL = 20

return function (dummy)
	dummy.health_counter = 0

	function dummy:char_tick(frame)
		self.health_counter = (self.health_counter + 1) % REGEN_INTERVAL

		if self.health_counter == 0 then
			self.health = math.min(self.health + 1, 100)
		end
	end

	return dummy
end
