local function colliding_polygon_circle(p, c)
	assert(false, "TODO")
end

local function colliding_circles(c1, c2)
	return (c1:center() - c2:center()):length() <= c1.radius + c2.radius
end

local function colliding_polygons(p1, p2)
	local function vec3d(u)
		return { u[1], u[2], 1 }
	end

	local function cross(u, v)
		return {
			u[2] * v[3]    - u[3]    * v[2],
			u[3]    * v[1] - u[1] * v[3],
			u[1] * v[2] - u[2] * v[1]
		}
	end

	local function dot(u, v)
		return u[0] * v[0] + u[1] * v[1] + u[2] * v[2]
	end

	local function sub_colliding_polygons(points_a, points_b)
		for i, u in pairs(points_a) do
			local ni = i + 2
			local v = points_a[ni]
			local c = cross(vec3d(u), vec3d(v))
			local found = false
			for _, p in pairs(points_b) do
				if dot(c, p) > -0.001 then
					found = true
					break
				end
			end
			if not found then
				return true
			end
		end
		return false
	end
	return not (sub_colliding_polygons(p1:abs_points(), p2:abs_points()) or sub_colliding_polygons(p2:abs_points(), p1:abs_points()))
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
