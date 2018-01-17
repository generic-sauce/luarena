local vec_mod = require('viewmath/vec')

local polygon_mod = {}

-- points are relative to the center!
function polygon_mod.by_center_and_points(center_vec, points)
	assert(center_vec)
	assert(points)
	assert(#points > 0)

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
	return polygon_mod.by_center_and_points(rect:center(), {rect:right_top(), rect:left_top(), rect:left_bottom(), rect:right_bottom()})
end

return polygon_mod
