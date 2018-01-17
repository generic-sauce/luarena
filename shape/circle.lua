local vec_mod = require('viewmath/vec')

local circle_mod = {}

function circle_mod.by_center_and_radius(center_vec, radius)
	assert(center_vec)
	assert(radius)

	local circle = {
		center_vec = center_vec,
		radius = radius
		shape_type = "circle"
	}

	function circle:with_center(center)
		return circle_mod.by_center_and_radius(
			center,
			self.radius
		)
	end

	function circle:move_center(center_add)
		return circle_mod.by_center_and_radius(
			self:center() + center_add,
			self.radius
		)
	end

	function circle:center() 
		return self.center_vec
	end

	return circle
end

return circle_mod
