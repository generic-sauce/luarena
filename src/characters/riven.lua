local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local task_mod = require('frame/task')
local skill_mod = require('frame/skill')

local S1_COOLDOWN = 5
local S1_TIMEOUT = 2.5
local S1_DASH_COOLDOWN = .35
local S1_DASH_INSTANCES = 3
local S1_DASH_DISTANCE = 65
local S1_DASH_SPEED = 400 -- units per second
local S1_ATTACK_DAMAGE = 20
local S1_ATTACK_SIZE = vec_mod(32, 32)

local S2_COOLDOWN = 5
local S2_ANIMATION_TIMEOUT = 0.2
local S2_SIZE = vec_mod(60, 60)
local S2_STUN_TIMEOUT = .3
local S2_DAMAGE = 20

local S3_COOLDOWN = 2
local S3_DASH_DISTANCE = 80
local S3_DASH_SPEED = 400 -- units per second
local S3_SHIELD_TIMEOUT = .5
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

	function area:tick()
		local entity = self.owner

		self.timeout = math.max(0, self.timeout - FRAME_DURATION)

		if self.timeout == 0 then
			frame():remove(self)
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

	function task:tick(entity)
		self.timeout = math.max(0, self.timeout - FRAME_DURATION)
		self.dash_cooldown = math.max(0, self.dash_cooldown - FRAME_DURATION)

		if self.instances == 0 or self.timeout == 0 then
			entity:remove_task(self)
		end
	end

	return task
end

local function generate_s1_dash_task(dash_direction)
	assert(dash_direction ~= nil)

	local task = {class = "riven_s1_dash", dash_direction = dash_direction, traveled_distance = 0 }

	function task:init(entity)
		local attack = generate_relative_area(
			entity,
			S1_DASH_DISTANCE / S1_DASH_SPEED,
			dash_direction:with_length(10),
			S1_ATTACK_SIZE)

		function attack:on_enter_collider(entity)
			local attack = self

			if entity.damage ~= nil and entity ~= self.owner and not (entity.owner and entity.owner == attack.owner) then
				entity:damage(S1_ATTACK_DAMAGE)
			end
		end

		frame():add(attack)
	end

	function task:tick(entity)
		entity.shape = entity.shape:move_center(self.dash_direction:with_length(S1_DASH_SPEED * FRAME_DURATION))
		self.traveled_distance = self.traveled_distance + S1_DASH_SPEED * FRAME_DURATION
		if self.traveled_distance >= S1_DASH_DISTANCE then
			entity:remove_task(self)
		end
	end

	return task
end

-- TODO create s1 wait task for sub dashes

return function (character)
	character.skills = {
		(function()
			local skill = {}
			skill.owner = character
			skill.cooldown = 0
			skill.dash_cooldown = 0

			function skill:draw() end

			function skill:tick()
				self.cooldown = math.max(0, self.cooldown - FRAME_DURATION)
				if self.owner.inputs.skill1 then
					local s1_tasks = self.owner:get_tasks_by_class("riven_s1")
					assert(not (#s1_tasks > 1), stringify(s1_tasks, 3))

					if #s1_tasks == 1 then
						local s1_task = s1_tasks[1]

						if s1_task.dash_cooldown == 0 then
							s1_task.dash_cooldown = S1_DASH_COOLDOWN
							s1_task.instances = math.max(0, s1_task.instances - 1)
							s1_task.timeout = S1_TIMEOUT
							self.owner:add_task(generate_s1_dash_task(self.owner:direction()))
						end
					elseif #s1_tasks == 0 and self.cooldown == 0 then
						self.cooldown = S1_COOLDOWN
						local s1_task = generate_s1_task()
						s1_task.instances = math.max(0, s1_task.instances - 1)
						self.owner:add_task(s1_task)
						self.owner:add_task(generate_s1_dash_task(self.owner:direction()))
						self.cooldown = S1_COOLDOWN
					end
				end
			end

			return skill
		end)(),

		(function()
			local skill = skill_mod.make_blank_skill(character, 2)
			skill_mod.with_cooldown(skill, S2_COOLDOWN)

			skill_mod.append_function(skill.task, "init", function(self)
				local attack = generate_relative_area(
					self.owner,
					S2_ANIMATION_TIMEOUT,
					vec_mod(0, 0),
					S2_SIZE)

				for _, entity in pairs(frame():find_colliders(attack.shape)) do
					if entity.damage and entity ~= attack.owner and not (entity.owner and entity.owner == attack.owner) then
						entity:damage(S2_DAMAGE)
					end
				end
				frame():add(attack)
			end)

			return skill
		end)(),

		(function()
			local skill = skill_mod.make_blank_skill(character, 3)
			skill_mod.with_cooldown(skill, S3_COOLDOWN)

			skill_mod.append_function(skill.task, "init", function(self)
				self.traveled_distance = 0
				self.dash_direction = self.owner:direction()
				local shield = generate_relative_area(
					self.owner,
					S3_SHIELD_TIMEOUT,
					vec_mod(0, 0),
					S3_SHIELD_SIZE)

				function shield:damage(dmg)
					frame():remove(self)
				end

				shield.owner = self.owner
				frame():add(shield)
			end)

			skill_mod.append_function(skill.task, "tick", function(self)
				self.owner.shape = self.owner.shape:move_center(self.dash_direction:with_length(S3_DASH_SPEED * FRAME_DURATION))
				self.traveled_distance = self.traveled_distance + S3_DASH_SPEED * FRAME_DURATION
				if self.traveled_distance >= S3_DASH_DISTANCE then
					self.owner:remove_task(self)
				end
			end)

			return skill
		end)()
	}

	return character
end
