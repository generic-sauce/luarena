local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

local REGEN_DELAY = 500

return function (dummy)
	dummy.regen_counter = 0

	function dummy:char_tick(frame)
		if self.health < 100 then
			self.regen_counter = self.regen_counter + 1
			if self.regen_counter == REGEN_DELAY then
				self.health = 100
				self.regen_counter = 0
			end
		else
			self.regen_counter = 0
		end
	end

	function dummy:on_damage(damage)
		self.regen_counter = 0
		self.health = math.max(0, self.health - damage)
	end

	return dummy
end
