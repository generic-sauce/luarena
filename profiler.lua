require('misc')

local profiler_mod = {}

-- global list
profilers = {}

function profiler_mod.start(name)
	local profiler = nil
	if profilers[name] then
		profiler = profilers[name]
	else
		profiler = {}
		profiler.name = name
		profiler.func = func
		profiler.times = {}
		profiler.start_times = {} -- is an array because of recursion!

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

	table.insert(profiler.start_times, love.timer.getTime())
end

function profiler_mod.stop(name)
	local profiler = profilers[name]

	table.insert(profiler.times, love.timer.getTime() - profiler.start_times[#profiler.start_times])
	profiler.start_times[#profiler.start_times] = nil
end

return profiler_mod
