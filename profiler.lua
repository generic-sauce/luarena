require('misc')

-- global list
profilers = {}

return function(name, func, ...)
	local profiler = nil
	if profilers[name] then
		profiler = profilers[name]
	else
		profiler = {}
		profiler.name = name
		profiler.func = func
		profiler.times = {}

		profilers[name] = profiler

		function profiler:get_avg()
			local sum = 0
			for _, t in pairs(self.times) do
				sum = sum + t
			end
			return sum / #self.times
		end

		function profiler:get_min()
			local min = nil
			for _, t in pairs(self.times) do
				if min == nil or t < min then
					min = t
				end
			end
			return min
		end

		function profiler:get_max()
			local max = nil
			for _, t in pairs(self.times) do
				if max == nil or t > max then
					max = t
				end
			end
			return max
		end
	end

	local start = love.timer.getTime()
	local out = profiler.func(...)
	local time = love.timer.getTime() - start
	table.insert(profiler.times, time)
	return out
end
