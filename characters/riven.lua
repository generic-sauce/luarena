local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local task_mod = require('frame/task')

local Q_COOLDOWN = 1000
local Q_TIMEOUT = 500
local Q_DASH_COOLDOWN = 70
local Q_DASH_INSTANCES = 3
local Q_DASH_DISTANCE = 65
local Q_DASH_SPEED = 2
local Q_ATTACK_DAMAGE = 20
local Q_ATTACK_SIZE = vec_mod(32, 32)

local W_COOLDOWN = 1000
local W_ANIMATION_TIMEOUT = 40
local W_SIZE = vec_mod(60, 60)
local W_STUN_TIMEOUT = 60
local W_DAMAGE = 20

local E_COOLDOWN = 400
local E_DASH_DISTANCE = 80
local E_DASH_SPEED = 2
local E_SHIELD_TIMEOUT = 100
local E_SHIELD_SIZE = vec_mod(35, 35)

local function generate_relative_area(entity, timeout, relative_position, size)
	local area = {}
	area.owner = entity
	area.shape = polygon_mod.by_rect(
			rect_mod.by_center_and_size(
				entity.shape:center() + relative_position,
				size
			)
	)
	area.timeout = timeout

	function area:tick(frame)
		self.timeout = math.max(0, self.timeout - 1)

		if self.timeout == 0 then
			frame:remove(self)
		else
			self.shape = self.shape:with_center(entity.shape:center() + relative_position)
		end
	end

	function area:draw(viewport)
		viewport:draw_shape(self.shape, 0, 0, 255)
	end

	return area
end

local function generate_q_task()
	local task = {class = "riven_q",
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

	local task = {class = "riven_q_dash", dash_target = dash_target }

	function task:init(entity, frame)
		local attack = generate_relative_area(
			entity,
			Q_DASH_DISTANCE / Q_DASH_SPEED,
			(self.dash_target - entity.shape:center()):with_length(10),
			Q_ATTACK_SIZE)

		function attack:on_enter_collider(frame, entity)
			if entity.damage ~= nil and entity ~= self.owner and not (entity.owner and entity.owner == attack.owner) then
				entity:damage(Q_ATTACK_DAMAGE)
			end
		end

		frame:add(attack)
	end

	function task:tick(entity, frame)
		local move_vec = self.dash_target - entity.shape:center()
		if move_vec:length() < Q_DASH_SPEED then
			entity.shape = entity.shape:with_center(self.dash_target)
			entity:remove_task(self)
		else
			entity.shape.center_vec = entity.shape:center() + move_vec:with_length(Q_DASH_SPEED)
		end
	end

	return task
end

local function generate_w_stun_task()
	local task = {class = "riven_w_stun",
		timeout = W_STUN_TIMEOUT}

	function task:tick(entity, frame)
		self.timeout = math.max(0, self.timeout - 1)

		if self.timeout == 0 then
			entity:remove_task(self)
		end
	end

	return task
end

local function generate_w_task()
	local task = {class = "riven_w",
		animation_timeout = W_ANIMATION_TIMEOUT}

	function task:init(entity, frame)
		local attack = generate_relative_area(
			entity,
			W_ANIMATION_TIMEOUT,
			vec_mod(0, 0),
			W_SIZE)

		for _, entity in pairs(frame:find_colliders(attack.shape)) do
			if entity.damage and entity ~= attack.owner and not (entity.owner and entity.owner == attack.owner) then
				entity:damage(W_DAMAGE)
				entity:add_task(generate_w_stun_task())
			end
		end

		frame:add(attack)
	end

	function task:tick(entity, frame)
		entity:remove_task(self)
	end

	return task
end

local function generate_e_task(dash_target)
	assert(dash_target ~= nil)

	local task = {class = "riven_e", dash_target = dash_target}

	function task:init(entity, frame)
		local shield = generate_relative_area(
			entity,
			E_SHIELD_TIMEOUT,
			vec_mod(0, 0),
			E_SHIELD_SIZE)

		function shield:damage(dmg)
			-- TODO doesnt work multiplayer
			frame:remove(shield)
		end

		shield.owner = entity
		frame:add(shield)
	end

	function task:tick(entity, frame)
		local move_vec = self.dash_target - entity.shape:center()
		if move_vec:length() < E_DASH_SPEED then
			entity.shape = entity.shape:with_center(self.dash_target)
			entity:remove_task(self)
		else
			entity.shape.center_vec = entity.shape:center() + move_vec:with_length(E_DASH_SPEED)
		end
	end

	return task
end

return function (character)
	character.q_cooldown = 0
	character.w_cooldown = 0
	character.e_cooldown = 0

	character.inputs.q = true
	character.inputs.w = true
	character.inputs.e = true

	function character:char_tick()
		-- TODO create q wait task for sub dashes

		self.q_cooldown = math.max(0, self.q_cooldown - 1)
		self.w_cooldown = math.max(0, self.w_cooldown - 1)
		self.e_cooldown = math.max(0, self.e_cooldown - 1)

		if self.inputs.q then
			local q_tasks = self:get_tasks_by_class("riven_q")
			assert(not (#q_tasks > 1), stringify(q_tasks))

			if #q_tasks == 1 then
				local q_task = q_tasks[1]

				if q_task.dash_cooldown == 0 then
					q_task.dash_cooldown = Q_DASH_COOLDOWN
					q_task.instances = math.max(0, q_task.instances - 1)
					q_task.timeout = Q_TIMEOUT
					self:add_task(generate_q_dash_task(self.shape:center() +
						(self.inputs.mouse - self.shape:center()):with_length(Q_DASH_DISTANCE)))
				end
			elseif #q_tasks == 0 and self.q_cooldown == 0 then
				self.q_cooldown = Q_COOLDOWN
				local q_task = generate_q_task()
				q_task.instances = math.max(0, q_task.instances - 1)
				self:add_task(q_task)
				self:add_task(generate_q_dash_task(self.shape:center() +
					(self.inputs.mouse - self.shape:center()):with_length(Q_DASH_DISTANCE)))
			end
		end

		if self.inputs.w and self.w_cooldown == 0 then
			self.w_cooldown = W_COOLDOWN
			self:add_task(generate_w_task())
		end

		if self.inputs.e and self.e_cooldown == 0 then
			self.e_cooldown = E_COOLDOWN
			self:add_task(generate_e_task(self.shape:center() +
				(self.inputs.mouse - self.shape:center()):with_length(E_DASH_DISTANCE)))
		end
	end

	return character
end
