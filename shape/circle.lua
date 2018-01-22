local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')

local profiler_mod = require('profiler')

local circle_mod = {}

function circle_mod.by_center_and_radius(center_vec, radius)
	assert(center_vec)
	assert(radius)

	local circle = {
		center_vec = center_vec,
		radius = radius,
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

	function circle:wrapper()
		profiler_mod.start('circle:wrapper')
		local ret = rect_mod.by_center_and_size(
			self:center(),
			vec_mod(self.radius * 2, self.radius * 2)
		)
		profiler_mod.stop('circle:wrapper')
		return ret
	end

	function circle:contains(point)
		return (point - self:center()):length() <= self.radius
	end

	return circle
end

return circle_mod
