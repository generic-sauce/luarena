-- vectors are immutable atomic data structures, never access their members directly

local vec_mod = require('viewmath/vec')

local rect_mod = {}

local meta = {
	__tostring = function(self)
		return "rect(center=" .. tostring(self.center_vec) .. ", size=" .. tostring(self.size_vec) .. ")"
	end,
	__index = {
		with_size_keep_center = function(self, size)
			return rect_mod.by_center_and_size(
				self:center(),
				size
			)
		end,
		with_center_keep_size = function(self, center)
			return rect_mod.by_center_and_size(
				center,
				self:size()
			)
		end,
		center = function(self)
			return self.center_vec
		end,
		size = function(self)
			return self.size_vec
		end,
		left = function(self)
			return self:center().x - self:size().x/2
		end,
		right = function(self)
			return self:center().x + self:size().x/2
		end,
		top = function(self)
			return self:center().y - self:size().y/2
		end,
		bottom = function(self)
			return self:center().y + self:size().y/2
		end,
		contains = function(self, vec)
			return self:left() <= vec.x
				and self:right() >= vec.x
				and self:top() <= vec.y
				and self:bottom() >= vec.y
		end,
		surrounds = function(self, other_rect)
			return self:left() <= other_rect:left()
				and self:right() >= other_rect:right()
				and self:top() <= other_rect:top()
				and self:bottom() >= other_rect:bottom()
		end,
		intersects = function(self, r2)
			return self:left() <= r2:right()
				and r2:left() <= self:right()
				and self:top() <= r2:bottom()
				and r2:top() <= self:bottom()
		end,
		left_top = function(self)
			return vec_mod(self:left(), self:top())
		end,
		left_bottom = function(self)
			return vec_mod(self:left(), self:bottom())
		end,
		right_bottom = function(self)
			return vec_mod(self:right(), self:bottom())
		end,
		right_top = function(self)
			return vec_mod(self:right(), self:top())
		end,
		width = function(self)
			return self:size().x
		end,
		height = function(self)
			return self:size().y
		end
	}
}

rect_mod.by_center_and_size = function(center, size)
	assert(center)
	assert(size)

	local rect = setmetatable({
		center_vec = center,
		size_vec = size
	}, meta)

	return rect
end

rect_mod.by_left_top_and_size = function(left_top, size)
	return rect_mod.by_center_and_size(left_top + size/2, size)
end

return rect_mod
