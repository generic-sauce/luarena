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
			return self:sum() / #self.times
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

		function profiler:sum()
			local sum = 0
			for _, t in pairs(self.times) do
				sum = sum + t
			end
			return sum
		end
	end

	table.insert(profiler.start_times, love.timer.getTime())
end

function profiler_mod.stop(name)
	local profiler = profilers[name]

	table.insert(profiler.times, love.timer.getTime() - profiler.start_times[#profiler.start_times])
	profiler.start_times[#profiler.start_times] = nil
end

function profiler_mod.dump_all()
	local function format_float(f)
		return string.format("%.5f", f)
	end

	local times_length = 0
	local name_length = 0
	for _, profiler in pairs(profilers) do
		if #profiler.times > 0 then
			name_length = math.max(name_length, #profiler.name)
			times_length = math.max(times_length, #tostring(#profiler.times))
		end
	end

	print("=================")
	for _, profiler in pairs(profilers) do
		if #profiler.times > 0 then
			print("profiler: \"" .. string.format("%" .. name_length .. "s", profiler.name) .. "\": ", format_float(profiler:get_min()) .. " <= " .. format_float(profiler:get_avg()) .. " <= " .. format_float(profiler:get_max()) .. ", count=" .. string.format("%" .. times_length .. "s", #profiler.times) .. ", sum=" .. format_float(profiler:sum()))
		end
	end
	print("=================")
end

return profiler_mod
