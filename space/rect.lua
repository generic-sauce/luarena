-- vectors are immutable atomic data structures, never access their members directly

local vec_mod = require('space/vec')

local rect_mod = {}

rect_mod.by_center_and_size = function(center, size)
	assert(center ~= nil)
	assert(size ~= nil)

	local meta = {
		__tostring = function(self)
			return "rect(center=" .. tostring(self.center_vec) .. ", size=" .. tostring(self.size_vec) .. ")"
		end
	}

	local rect = setmetatable({
		center_vec = center,
		size_vec = size
	}, meta)

	function rect:with_size_keep_center(size)
		return rect_mod.by_center_and_size(
			self:center(),
			size
		)
	end

	function rect:with_center_keep_size(center)
		return rect_mod.by_center_and_size(
			center,
			self:size()
		)
	end

	function rect:center() 
		return self.center_vec
	end

	function rect:size() 
		return self.size_vec
	end

	function rect:left()
		return self:center().x - self:size().x/2
	end

	function rect:right()
		return self:center().x + self:size().x/2
	end

	function rect:top()
		return self:center().y - self:size().y/2
	end

	function rect:bottom()
		return self:center().y + self:size().y/2
	end

	function rect:contains(vec)
		print("TODO")
		assert(false)
	end

	function rect:surrounds(other_rect)
		return self:left() <= other_rect:left()
			and self:right() >= other_rect:right()
			and self:top() <= other_rect:top()
			and self:bottom() >= other_rect:bottom()
	end

	function rect:intersects(r2)
		return self:left() <= other_rect:right()
			and r2:left() <= self:right()
			and self:top() <= r2:bottom()
			and r2:top() >= self:bottom()
	end

	function rect:left_top()
		return vec_mod(self:left(), self:top())
	end

	function rect:width()
		return self:size().x
	end

	function rect:height()
		return self:size().y
	end

	return rect
end

rect_mod.by_left_top_and_size = function(left_top, size)
	return rect_mod.by_center_and_size(left_top + size/2, size)
end

return rect_mod
