local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
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

	function map:draw(viewport)
		local r = self:rect()
		viewport:draw_world_rect(r, 70, 70, 10)
		local step = 50

		local minx = math.floor(r:left() / step) * step
		local maxx = (math.ceil(r:right() / step) - 1) * step
		local miny = math.floor(r:top() / step) * step
		local maxy = (math.ceil(r:bottom() / step) - 1) * step

		for x=minx, maxx, step do
			for y=miny, maxy, step do
				viewport:draw_world_rect(rect_mod.by_left_top_and_size(vec_mod(x, y), vec_mod(20, 20)), 65, 65, 13)
			end
		end
	end

	return map
end

return map_mod
