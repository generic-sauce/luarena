local vec_mod = require("viewmath/vec")

-- checks on what side of a line `line_start to line_end` the point `p` is
local function point_is_on_right_side(line_start, line_end, p)
	local vec_from_line_start_to_p = p - line_start
	local line_right_vec = line_start:cross(line_end)
	local ret = vec_from_line_start_to_p:dot(line_right_vec) >= 0
	return ret
end

local function one_mod(k, n)
	return ((k-1) % n) + 1
end

local function assert_convex_points(points)
	for i, _ in pairs(points) do
		local line_start = points[i]
		local line_end = points[one_mod(i+2, #points)]
		local p = points[one_mod(i+1, #points)]
		assert(point_is_on_right_side(line_start, line_end, p), "polygon is not convex!")
	end
end

local function colliding_polygon_circle(p, c)
	local points = p:abs_points()
	assert_convex_points(points)

	-- checks whether the circle c is completely on the right side of the line `line_start to line_end`
	local function circle_is_on_right_side(line_start, line_end, c)
		local line_right_vec = line_start:cross(line_end)

		local move_vec = line_right_vec:with_length(c.radius)

		-- move imaginary line to the right, as much as the radius of c
		local moved_line_start = line_start + move_vec
		local moved_line_end = line_end + move_vec

		local vec_from_moved_line_start_to_center = c:center() - moved_line_start
		local ret = vec_from_moved_line_start_to_center:dot(line_right_vec) >= 0
		return ret
	end

	local function has_separating_axis_to_circle(points, c)
		for i, u in pairs(points) do
			local v = points[i + 1] or points[1]

			-- as points_a are stored in counter clockwise order:
			--		the right side of the axis means "out of the body (points_a)"
			--		and the left side of the axis means "inside of the body (points_a)"

			if circle_is_on_right_side(u, v, c) then
				return true
			end
		end
		return false
	end

	local colliding = not has_separating_axis_to_circle(points, c)
	return colliding
end

local function colliding_circles(c1, c2)
	return (c1:center() - c2:center()):length() <= c1.radius + c2.radius
end

local function colliding_polygons(p1, p2)
	local function has_separating_axis_to_point(points_a, points_b)
		-- if there is one axis
		for i, u in pairs(points_a) do
			local v = points_a[i + 1] or points_a[1]

			local may_be_sep_axis = true
			-- for which all other points are on the outer side
			for _, p in pairs(points_b) do
				-- as points_a are stored in counter clockwise order:
				--		the right side of the axis means "out of the body (points_a)"
				--		and the left side of the axis means "inside of the body (points_a)"
				if not point_is_on_right_side(u, v, p) then
					may_be_sep_axis = false
					break
				end
			end
			if may_be_sep_axis then
				return true
			end
		end
		return false
	end

	local points_a = p1:abs_points()
	local points_b = p2:abs_points()
	assert_convex_points(points_a)
	assert_convex_points(points_b)
	local ret = not (has_separating_axis_to_point(points_a, points_b) or has_separating_axis_to_point(points_b, points_a))

	return ret
end

return function(shape1, shape2)
	if shape1.shape_type == "polygon" then
		if shape2.shape_type == "polygon" then
			return colliding_polygons(shape1, shape2)
		elseif shape2.shape_type == "circle" then
			return colliding_polygon_circle(shape1, shape2)
		else
			assert(false)
		end
	elseif shape1.shape_type == "circle" then
		if shape2.shape_type == "polygon" then
			return colliding_polygon_circle(shape2, shape1)
		elseif shape2.shape_type == "circle" then
			return colliding_circles(shape1, shape2)
		else
			assert(false)
		end
	else
		assert(false)
	end
end
