local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local line_mod = require('collision/line')

local dev = require('dev')

require('misc')

local polygon_mod = {}

local function assert_convex_points(points)
	dev.start_profiler('assert_convex_points', {"collision"})
	for i, _ in pairs(points) do
		local line_start = points[i]
		local line_end = get(points, i+2)
		local p = get(points, i+1)
		assert(line_mod(line_start, line_end):is_right(p), "polygon is not convex!")
	end
	dev.stop_profiler('assert_convex_points')
end

-- points are relative to the center!
function polygon_mod.by_center_and_points(center_vec, points)
	assert(center_vec)
	assert(points)
	assert(#points > 0)

	assert_convex_points(points)

	local polygon = {
		center_vec = center_vec,

		-- for the collision detection these points have to be counter clockwise!
		-- should be relative to the center
		points = points,
		shape_type = "polygon"
	}

	function polygon:with_center(center)
		return polygon_mod.by_center_and_points(
			center,
			self.points
		)
	end

	function polygon:move_center(center_add)
		return polygon_mod.by_center_and_points(
			self.center_vec + center_add,
			self.points
		)
	end

	function polygon:abs_points()
		local out = {}
		for _, p in pairs(self.points) do
			table.insert(out, self:center() + p)
		end
		return out
	end

	function polygon:center() 
		return self.center_vec
	end

	function polygon:wrapper()
		dev.start_profiler('polygon:wrapper', {"collision"})
		if not self.wrapper_cache then
			local left, right, top, bottom
			for _, p in pairs(self:abs_points()) do
				if not left or left > p.x then left = p.x end
				if not right or right < p.x then right = p.x end
				if not top or top > p.y then top = p.y end
				if not bottom or bottom < p.y then bottom = p.y end
			end
			self.wrapper_cache = rect_mod.by_left_top_and_size(
				vec_mod(left, top),
				vec_mod(right - left, bottom - top)
			)
		end
		dev.stop_profiler('polygon:wrapper')
		return self.wrapper_cache
	end

	function polygon:contains(point)
		local points = self:abs_points()

		for i, p in pairs(points) do
			local axis = line_mod(p, get(points, i+1))
			if axis:is_right(point) then
				return false
			end
		end

		return true
	end

	return polygon
end

function polygon_mod.by_points(points)
	local sum = vec_mod(0, 0)
	for _, v in pairs(points) do
		sum = sum + v
	end
	local center = sum / #points

	rel_points = {}
	for _, p in pairs(points) do
		table.insert(rel_points, p - center)
	end

	return polygon_mod.by_center_and_points(center, rel_points)
end


function polygon_mod.by_rect(rect)
	local p = polygon_mod.by_center_and_points(rect:center(), {
		rect:right_top()    - rect:center(),
		rect:left_top()     - rect:center(),
		rect:left_bottom()  - rect:center(),
		rect:right_bottom() - rect:center()
	})
	p.rect = rect -- this rect may be used by some performance critical code-parts
	return p
end

return polygon_mod
