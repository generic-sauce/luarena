local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

return function (dummy)
	function dummy:char_tick(frame)
		self.health = math.min(self.health + 1, 100)
	end

	return dummy
end
