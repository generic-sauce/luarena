local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local task_mod = require('frame/task')

local S1_COOLDOWN = 1000
local S1_TIMEOUT = 500
local S1_DASH_COOLDOWN = 70
local S1_DASH_INSTANCES = 3
local S1_DASH_DISTANCE = 65
local S1_DASH_SPEED = 2
local S1_ATTACK_DAMAGE = 20
local S1_ATTACK_SIZE = vec_mod(32, 32)

local S2_COOLDOWN = 1000
local S2_ANIMATION_TIMEOUT = 40
local S2_SIZE = vec_mod(60, 60)
local S2_STUN_TIMEOUT = 60
local S2_DAMAGE = 20

local S3_COOLDOWN = 400
local S3_DASH_DISTANCE = 80
local S3_DASH_SPEED = 2
local S3_SHIELD_TIMEOUT = 100
local S3_SHIELD_SIZE = vec_mod(35, 35)

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

local function generate_s1_task()
	local task = {class = "riven_s1",
		instances = S1_DASH_INSTANCES,
		dash_cooldown = S1_DASH_COOLDOWN,
		timeout = S1_TIMEOUT}

	function task:tick(entity, frame)
		self.timeout = math.max(0, self.timeout - 1)
		self.dash_cooldown = math.max(0, self.dash_cooldown - 1)

		if self.instances == 0 or self.timeout == 0 then
			entity:remove_task(self)
		end
	end

	return task
end

local function generate_s1_dash_task(dash_target)
	assert(dash_target ~= nil)

	local task = {class = "riven_s1_dash", dash_target = dash_target }

	function task:init(entity, frame)
		local attack = generate_relative_area(
			entity,
			S1_DASH_DISTANCE / S1_DASH_SPEED,
			(self.dash_target - entity.shape:center()):with_length(10),
			S1_ATTACK_SIZE)

		function attack:on_enter_collider(frame, entity)
			local attack = self

			if entity.damage ~= nil and entity ~= self.owner and not (entity.owner and entity.owner == attack.owner) then
				entity:damage(S1_ATTACK_DAMAGE)
			end
		end

		frame:add(attack)
	end

	function task:tick(entity, frame)
		local move_vec = self.dash_target - entity.shape:center()
		if move_vec:length() < S1_DASH_SPEED then
			entity.shape = entity.shape:with_center(self.dash_target)
			entity:remove_task(self)
		else
			entity.shape = entity.shape:move_center(move_vec:with_length(S1_DASH_SPEED))
		end
	end

	return task
end

local function generate_s2_stun_task()
	local task = {class = "riven_s2_stun",
		timeout = S2_STUN_TIMEOUT}

	function task:tick(entity, frame)
		self.timeout = math.max(0, self.timeout - 1)

		if self.timeout == 0 then
			entity:remove_task(self)
		end
	end

	return task
end

local function generate_s2_task()
	local task = {class = "riven_s2",
		animation_timeout = S2_ANIMATION_TIMEOUT}

	function task:init(entity, frame)
		local attack = generate_relative_area(
			entity,
			S2_ANIMATION_TIMEOUT,
			vec_mod(0, 0),
			S2_SIZE)

		for _, entity in pairs(frame:find_colliders(attack.shape)) do
			if entity.damage and entity ~= attack.owner and not (entity.owner and entity.owner == attack.owner) then
				entity:damage(S2_DAMAGE)
				entity:add_task(generate_s2_stun_task())
			end
		end

		frame:add(attack)
	end

	function task:tick(entity, frame)
		entity:remove_task(self)
	end

	return task
end

local function generate_s3_task(dash_target)
	assert(dash_target ~= nil)

	local task = {class = "riven_s3", dash_target = dash_target}

	function task:init(entity, frame)
		local shield = generate_relative_area(
			entity,
			S3_SHIELD_TIMEOUT,
			vec_mod(0, 0),
			S3_SHIELD_SIZE)

		function shield:damage(dmg)
			frame:remove(self)
		end

		shield.owner = entity
		frame:add(shield)
	end

	function task:tick(entity, frame)
		local move_vec = self.dash_target - entity.shape:center()
		if move_vec:length() < S3_DASH_SPEED then
			entity.shape = entity.shape:with_center(self.dash_target)
			entity:remove_task(self)
		else
			entity.shape = entity.shape:move_center(move_vec:with_length(S3_DASH_SPEED))
		end
	end

	return task
end

return function (character)
	character.s1_cooldown = 0
	character.s2_cooldown = 0
	character.s3_cooldown = 0

	function character:char_tick()
		-- TODO create s1 wait task for sub dashes

		self.s1_cooldown = math.max(0, self.s1_cooldown - 1)
		self.s2_cooldown = math.max(0, self.s2_cooldown - 1)
		self.s3_cooldown = math.max(0, self.s3_cooldown - 1)

		if self.inputs[S1_KEY] then
			local s1_tasks = self:get_tasks_by_class("riven_s1")
			assert(not (#s1_tasks > 1), stringify(s1_tasks))

			if #s1_tasks == 1 then
				local s1_task = s1_tasks[1]

				if s1_task.dash_cooldown == 0 then
					s1_task.dash_cooldown = S1_DASH_COOLDOWN
					s1_task.instances = math.max(0, s1_task.instances - 1)
					s1_task.timeout = S1_TIMEOUT
					self:add_task(generate_s1_dash_task(self.shape:center() +
						self:direction():with_length(S1_DASH_DISTANCE)))
				end
			elseif #s1_tasks == 0 and self.s1_cooldown == 0 then
				self.s1_cooldown = S1_COOLDOWN
				local s1_task = generate_s1_task()
				s1_task.instances = math.max(0, s1_task.instances - 1)
				self:add_task(s1_task)
				self:add_task(generate_s1_dash_task(self.shape:center() +
					self:direction():with_length(S1_DASH_DISTANCE)))
			end
		end

		if self.inputs[S2_KEY] and self.s2_cooldown == 0 then
			self.s2_cooldown = S2_COOLDOWN
			self:add_task(generate_s2_task())
		end

		if self.inputs[S3_KEY] and self.s3_cooldown == 0 then
			self.s3_cooldown = S3_COOLDOWN
			self:add_task(generate_s3_task(self.shape:center() +
				self:direction():with_length(S3_DASH_DISTANCE)))
		end
	end

	return character
end
