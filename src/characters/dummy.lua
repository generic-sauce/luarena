local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')

local REGEN_DELAY = 5 -- in seconds

return function (dummy)
	dummy.regen_counter = 0

	function dummy:color()
		return 255, 255, 255
	end

	function dummy:init() --[[ don't apply spawn protection! ]] end

	function dummy:char_tick()
		if self.health < 100 then
			self.regen_counter = self.regen_counter + FRAME_DURATION
			if self.regen_counter >= REGEN_DELAY then
				self.health = 100
				self.regen_counter = 0
			end
		else
			self.regen_counter = 0
		end
	end

	function dummy:damage(dmg)
		self.regen_counter = 0
		self.health = math.max(0, self.health - dmg)
	end

	dummy.skills = {}

	return dummy
end
