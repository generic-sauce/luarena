-- vectors are immutable atomic data structures, never access their members directly

function vec_mod(x, y)
	assert(x)
	assert(y)

	local meta = {}
	function meta:__index(i)
		if i == 1 then
			return self.x
		elseif i == 2 then
			return self.y
		else
			assert(false, "Vec: Index '" .. i .. "' out of range")
		end
	end

	function meta:__add(other)
		return vec_mod(self.x + other.x, self.y + other.y)
	end

	function meta:__sub(other)
		return vec_mod(self.x - other.x, self.y - other.y)
	end

	function meta:__mul(other)
		if type(other) ~= "table" then
			return vec_mod(self.x * other, self.y * other)
		end
		return vec_mod(self.x * other.x, self.y * other.y)
	end

	function meta:__div(other)
		if type(other) ~= "table" then
			return vec_mod(self.x / other, self.y / other)
		end
		return vec_mod(self.x / other.x, self.y / other.y)
	end

	function meta:__tostring()
		return "vec(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ")"
	end

	local v = setmetatable({ x = x, y = y }, meta)

	function v:length()
		return math.sqrt(self.x^2 + self.y^2)
	end

	function v:with_x(x)
		return vec_mod(x, self.y)
	end

	function v:with_y(y)
		return vec_mod(self.x, y)
	end

	function v:floor()
		return vec_mod(math.floor(self.x), math.floor(self.y))
	end

	function v:ceil()
		return vec_mod(math.ceil(self.x), math.ceil(self.y))
	end

	function v:normalized()
		return self / self:length()
	end

	function v:cropped_to(l)
		if self:length() > l then
			return self:normalized() * l
		else
			return self
		end
	end

	function v:with_length(l)
		return self:normalized() * l
	end

	function v:dot(w)
		return self[1] * w[1] + self[2] * w[2]
	end

	function v:cross(w)
		return vec_mod(
			self[2] * 1 - 1 * w[2],
			1 * w[1] - self[1] * 1
		)
	end

	return v
end

return vec_mod
