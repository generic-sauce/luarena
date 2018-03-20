-- vectors are immutable atomic data structures, never access their members directly

local meta = {}
meta.__index = {
	index = function (i)
		if i == 1 then
			return self.x
		elseif i == 2 then
			return self.y
		else
			assert(false, "vec:index - index out of range")
		end
	end,

	length = function(self)
		return math.sqrt(self.x^2 + self.y^2)
	end,
	with_x = function(self, x)
		return vec_mod(x, self.y)
	end,
	with_y = function(self, y)
		return vec_mod(self.x, y)

	add_x = function(self, x)
		return vec_mod(self.x + x, self.y)
	end,
	add_y = function(self, y)
		return vec_mod(self.x, self.y + y)
	end,

	floor = function(self)
		return vec_mod(math.floor(self.x), math.floor(self.y))
	end,
	ceil = function(self)
		return vec_mod(math.ceil(self.x), math.ceil(self.y))
	end,
	normalized = function(self)
		return self / self:length()
	end,
	cropped_to = function(self, l)
		if self:length() > l then
			return self:normalized() * l
		else
			return self
		end
	end,
	with_length = function(self, l)
		return self:normalized() * l
	end,
	dot = function(self, w)
		return self.x * w.x + self.y * w.y
	end,
	cross = function(self, w)
		return vec_mod(
			self.y * 1 - 1 * w.y,
			1 * w.x - self.x * 1
		)
	end
}

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

function vec_mod(x, y)
	assert(x)
	assert(y)

	local v = setmetatable({ x = x, y = y }, meta)

	return v
end

return vec_mod
