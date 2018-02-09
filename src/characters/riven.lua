local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local task_mod = require('frame/task')

local H_COOLDOWN = 1000
local H_TIMEOUT = 500
local H_DASH_COOLDOWN = 70
local H_DASH_INSTANCES = 3
local H_DASH_DISTANCE = 65
local H_DASH_SPEED = 2
local H_ATTACK_DAMAGE = 20
local H_ATTACK_SIZE = vec_mod(32, 32)

local J_COOLDOWN = 1000
local J_ANIMATION_TIMEOUT = 40
local J_SIZE = vec_mod(60, 60)
local J_STUN_TIMEOUT = 60
local J_DAMAGE = 20

local K_COOLDOWN = 400
local K_DASH_DISTANCE = 80
local K_DASH_SPEED = 2
local K_SHIELD_TIMEOUT = 100
local K_SHIELD_SIZE = vec_mod(35, 35)

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
		local entity = self.owner

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

local function generate_h_task()
	local task = {class = "riven_h",
		instances = H_DASH_INSTANCES,
		dash_cooldown = H_DASH_COOLDOWN,
		timeout = H_TIMEOUT}

	function task:tick(entity, frame)
		self.timeout = math.max(0, self.timeout - 1)
		self.dash_cooldown = math.max(0, self.dash_cooldown - 1)

		if self.instances == 0 or self.timeout == 0 then
			entity:remove_task(self)
		end
	end

	return task
end

local function generate_h_dash_task(dash_target)
	assert(dash_target ~= nil)

	local task = {class = "riven_h_dash", dash_target = dash_target }

	function task:init(entity, frame)
		local attack = generate_relative_area(
			entity,
			H_DASH_DISTANCE / H_DASH_SPEED,
			(self.dash_target - entity.shape:center()):with_length(10),
			H_ATTACK_SIZE)

		function attack:on_enter_collider(frame, entity)
			local attack = self

			if entity.damage ~= nil and entity ~= self.owner and not (entity.owner and entity.owner == attack.owner) then
				entity:damage(H_ATTACK_DAMAGE)
			end
		end

		frame:add(attack)
	end

	function task:tick(entity, frame)
		local move_vec = self.dash_target - entity.shape:center()
		if move_vec:length() < H_DASH_SPEED then
			entity.shape = entity.shape:with_center(self.dash_target)
			entity:remove_task(self)
		else
			entity.shape = entity.shape:move_center(move_vec:with_length(H_DASH_SPEED))
		end
	end

	return task
end

local function generate_j_stun_task()
	local task = {class = "riven_j_stun",
		timeout = J_STUN_TIMEOUT}

	function task:tick(entity, frame)
		self.timeout = math.max(0, self.timeout - 1)

		if self.timeout == 0 then
			entity:remove_task(self)
		end
	end

	return task
end

local function generate_j_task()
	local task = {class = "riven_j",
		animation_timeout = J_ANIMATION_TIMEOUT}

	function task:init(entity, frame)
		local attack = generate_relative_area(
			entity,
			J_ANIMATION_TIMEOUT,
			vec_mod(0, 0),
			J_SIZE)

		for _, entity in pairs(frame:find_colliders(attack.shape)) do
			if entity.damage and entity ~= attack.owner and not (entity.owner and entity.owner == attack.owner) then
				entity:damage(J_DAMAGE)
				entity:add_task(generate_j_stun_task())
			end
		end

		frame:add(attack)
	end

	function task:tick(entity, frame)
		entity:remove_task(self)
	end

	return task
end

local function generate_k_task(dash_target)
	assert(dash_target ~= nil)

	local task = {class = "riven_k", dash_target = dash_target}

	function task:init(entity, frame)
		local shield = generate_relative_area(
			entity,
			K_SHIELD_TIMEOUT,
			vec_mod(0, 0),
			K_SHIELD_SIZE)

		function shield:damage(dmg)
			frame:remove(self)
		end

		shield.owner = entity
		frame:add(shield)
	end

	function task:tick(entity, frame)
		local move_vec = self.dash_target - entity.shape:center()
		if move_vec:length() < K_DASH_SPEED then
			entity.shape = entity.shape:with_center(self.dash_target)
			entity:remove_task(self)
		else
			entity.shape = entity.shape:move_center(move_vec:with_length(K_DASH_SPEED))
		end
	end

	return task
end

return function (character)
	character.h_cooldown = 0
	character.j_cooldown = 0
	character.k_cooldown = 0

	character.inputs.h = true
	character.inputs.j = true
	character.inputs.k = true

	function character:char_tick()
		-- TODO create h wait task for sub dashes

		self.h_cooldown = math.max(0, self.h_cooldown - 1)
		self.j_cooldown = math.max(0, self.j_cooldown - 1)
		self.k_cooldown = math.max(0, self.k_cooldown - 1)

		if self.inputs.h then
			local h_tasks = self:get_tasks_by_class("riven_h")
			assert(not (#h_tasks > 1), stringify(h_tasks))

			if #h_tasks == 1 then
				local h_task = h_tasks[1]

				if h_task.dash_cooldown == 0 then
					h_task.dash_cooldown = H_DASH_COOLDOWN
					h_task.instances = math.max(0, h_task.instances - 1)
					h_task.timeout = H_TIMEOUT
					self:add_task(generate_h_dash_task(self.shape:center() +
						self:direction():with_length(H_DASH_DISTANCE)))
				end
			elseif #h_tasks == 0 and self.h_cooldown == 0 then
				self.h_cooldown = H_COOLDOWN
				local h_task = generate_h_task()
				h_task.instances = math.max(0, h_task.instances - 1)
				self:add_task(h_task)
				self:add_task(generate_h_dash_task(self.shape:center() +
					self:direction():with_length(H_DASH_DISTANCE)))
			end
		end

		if self.inputs.j and self.j_cooldown == 0 then
			self.j_cooldown = J_COOLDOWN
			self:add_task(generate_j_task())
		end

		if self.inputs.k and self.k_cooldown == 0 then
			self.k_cooldown = K_COOLDOWN
			self:add_task(generate_k_task(self.shape:center() +
				self:direction():with_length(K_DASH_DISTANCE)))
		end
	end

	return character
end
