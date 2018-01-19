local vec_mod = require("viewmath/vec")
local line_mod = require("collision/line")

local polygon_mod = require("shape/polygon")

require('misc')

local function colliding_polygon_circle(p, c)
	local points = p:abs_points()

	-- check whether circle center is in polygon
	if p:contains(c:center()) then
		return true
	end

	-- check whether circle center is in range of point (= point is in range of circle)
	for _, p in pairs(points) do
		if c:contains(p) then
			return true
		end
	end

	-- check whether circle center is in range of axis
	for i, u in pairs(points) do
		local v = get(points, i+1)
		local axis = line_mod(u, v)
		local offset = axis:right():with_length(c.radius)

		local axis_polygon = polygon_mod.by_points({
			u,
			u + offset,
			v + offset,
			v
		})
		if axis_polygon:contains(c:center()) then
			return true
		end
	end

	return false
end

local function colliding_circles(c1, c2)
	return (c1:center() - c2:center()):length() <= c1.radius + c2.radius
end

local function colliding_polygons(p1, p2)
	local function is_separating_axis_to_points(axis, points)
		for _, p in pairs(points) do
			-- as points_a are stored in counter clockwise order:
			--		the right side of the axis means "out of the body (points_a)"
			--		and the left side of the axis means "inside of the body (points_a)"
			if not axis:is_right(p) then
				return false
			end
		end
		return true
	end

	local function has_separating_axis_to_points(points_a, points_b)
		for i, u in pairs(points_a) do
			local v = get(points_a, i+1)
			if is_separating_axis_to_points(line_mod(u, v), points_b) then
				return true
			end
		end
		return false
	end

	local points_a = p1:abs_points()
	local points_b = p2:abs_points()
	local ret = not (has_separating_axis_to_points(points_a, points_b) or has_separating_axis_to_points(points_b, points_a))

	return ret
end

return function(shape1, shape2)
	return require("profiler")("collision_detection_mod", function(shape1, shape2)
		if not shape1:wrapper():intersects(shape2:wrapper()) then
			return false
		end

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
	end, shape1, shape2)
end
