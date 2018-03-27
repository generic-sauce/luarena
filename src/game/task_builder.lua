local func_mod = require('func')

return function(task_mod)
	function task_mod.with_instant(task, init)
		func_mod.append_function(task, "init", init)
		func_mod.append_function(task, "init", function(self) self.owner:remove_task(self) end)

		return skill
	end

	function task_mod.with_dash(task, range)
		task.dash_traveled_distance = 0
		task.dash_range = range

		func_mod.append_function(task, "tick", function(self)
			assert(self.dash_speed ~= nil, "dash_speed has not been set")

			if self.dash_traveled_distance >= self.dash_range then
				self.owner:remove_task(self)
			else
				local speed = self.dash_speed * FRAME_DURATION
				self.owner.shape = self.owner.shape:move_center(speed)
				self.dash_traveled_distance = self.dash_traveled_distance + speed:length()
			end
		end)

		return task
	end

end
