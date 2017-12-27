-- vectors are immutable atomic data structures, never access their members directly

function vec_mod(x, y)
	assert(x ~= nil)
	assert(y ~= nil)

	local meta = {}
	function meta:__index(i)
		if i == 0 then
			return self.x
		elseif i == 1 then
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
		return vec_mod(self.x * other, self.y * other)
	end

	function meta:__div(other)
		return vec_mod(self.x / other, self.y / other)
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

	return v
end

return vec_mod
