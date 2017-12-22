local rect_mod = require('space/rect')
local vec_mod = require('space/vec')
local map_mod = {}

function map_mod.new()
	local map = {}

	function map:size()
		return vec_mod(1000, 1000)
	end

	function map:rect()
		return rect_mod.by_left_top_and_size(
			vec_mod(0, 0),
			self:size()
		)
	end

	function map:draw(cam)
		return cam:draw_world_rect(self:rect(), 70, 70, 0)
	end

	return map
end

return map_mod
