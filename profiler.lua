require('misc')

-- global list
profilers = {}

return function(name, func, verbose)
	local profiler = nil
	if table.contains(profilers, name) then
		profiler = profilers[name]
	else
		profiler = {}
		profiler.name = name
		profiler.func = func
		profiler.times = {}

		if verbose then
			profiler.verbose = true
		else
			profiler.verbose = false
		end

		profilers[name] = profiler

		function profiler:run()
			local start = love.timer.getTime()
			func()
			local time = love.timer.getTime() - start
			table.insert(self.times, time)
			if self.verbose then
				print("profiler \"" .. self.name .. "\": " .. time)
			end
		end

		function profiler:get_avg()
			local sum = 0
			for _, t in pairs(self.times) do
				sum = sum + t
			end
			return sum / #self.times
		end
	end

	profiler:run()
end
