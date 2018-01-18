return function(from, to)
	assert(from)
	assert(to)
	local line = {}
	line.from = from
	line.to = to

	function line:direction()
		return (self.to - self.from):normalized()
	end

	function line:right()
		return self.from:cross(self.to)
	end

	function line:left()
		return self:right() * -1
	end

	function line:is_right(p)
		local vec = p - self.from
		local ret = vec:dot(self:right()) >= 0
		return ret
	end

	function line:is_left(p)
		local vec = p - self.from
		local ret = vec:dot(self:left()) >= 0
		return ret
	end

	return line
end
