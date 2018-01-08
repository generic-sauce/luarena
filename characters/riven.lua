local rect_mod = require('space/rect')
local vec_mod = require('space/vec')
local task_mod = require('frame/task')

local Q_COOLDOWN = 1000
local Q_TIMEOUT = 500
local Q_DASH_COOLDOWN = 70
local Q_DASH_INSTANCES = 3
local Q_DASH_DISTANCE = 50
local Q_DASH_SPEED = 2

local function generate_q_task()
	local task = {type = "riven_q",
		instances = Q_DASH_INSTANCES,
		dash_cooldown = Q_DASH_COOLDOWN,
		timeout = Q_TIMEOUT}

	function task:tick(entity, frame)
		self.timeout = math.max(0, self.timeout - 1)
		self.dash_cooldown = math.max(0, self.dash_cooldown - 1)

		if self.instances == 0 or self.timeout == 0 then
			entity:remove_task(self)
		end
	end

	return task
end

local function generate_q_dash_task(dash_target)
	assert(dash_target ~= nil)

	local task = {type = "riven_q_dash", dash_target = dash_target }

	function task:tick(entity, frame)
		local move_vec = self.dash_target - entity.shape:center()
		if move_vec:length() < Q_DASH_SPEED then
			entity.shape = entity.shape:with_center_keep_size(self.dash_target)
			entity:remove_task(self)
		else
			entity.shape.center_vec = entity.shape:center() + move_vec:with_length(Q_DASH_SPEED)
		end
	end

	return task
end


return function (character)
	character.q_cooldown = 0

	character.inputs.q = true

	function character:char_tick()
		-- TODO create q wait task for sub dashes

		self.q_cooldown = math.max(0, self.q_cooldown - 1)

		if self.inputs.q then
			local q_tasks = self:get_tasks("riven_q")
			assert(not (#q_tasks > 1))

			if #q_tasks == 1 then
				local q_task = q_tasks[1]

				if q_task.dash_cooldown == 0 then
					print("q dash")
					q_task.dash_cooldown = Q_DASH_COOLDOWN
					q_task.instances = math.max(0, q_task.instances - 1)
					q_task.timeout = Q_TIMEOUT
					self:add_task(generate_q_dash_task(self.shape:center() +
						(self.inputs.mouse - self.shape:center()):with_length(Q_DASH_DISTANCE)))
				end
			elseif #q_tasks == 0 and self.q_cooldown == 0 then
				print("q")
				self.q_cooldown = Q_COOLDOWN
				local q_task = generate_q_task()
				q_task.instances = math.max(0, q_task.instances - 1)
				self:add_task(q_task)
				self:add_task(generate_q_dash_task(self.shape:center() +
					(self.inputs.mouse - self.shape:center()):with_length(Q_DASH_DISTANCE)))
			end
		end
	end

	return character
end
