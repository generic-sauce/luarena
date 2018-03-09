-- unnamed character 1

local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local circle_mod = require('shape/circle')

local collision_detection_mod = require('collision/detection')

local S1_COOLDOWN = 6
local S1_RANGE = 75
local S1_DAMAGE = 20
local S1_SPEED = 200

local S2_COOLDOWN = 1.5
local S2_RANGE = 100
local S2_SPEED = 600 -- units per second
local S2_MAX_DAGGERS = 4
local S2_DAMAGE = 5

local S3_COOLDOWN = 6
local S3_RANGE = 100
local S3_SPEED = 400 -- units per second
local S3_DAMAGE = 12

local S4_COOLDOWN = 1.5
local S4_DAMAGE = 15
local S4_DAMAGE_ADD = 15
local S4_RANGE = 25
local S4_DURATION = .4

return function (u1)

	u1.dagger_list = {}

	u1.s1_cooldown = 0
	u1.s2_cooldown = 0
	u1.s3_cooldown = 0
	u1.s4_cooldown = 0

	u1.s1_released = true
	u1.s2_released = true
	u1.s3_released = true
	u1.s4_released = true

	function u1:use_s1_skill()
		local u1 = self

		local task = { class = "u1_s1" }

		function task:init(u1)
			local task = self

			u1.s1_cooldown = S1_COOLDOWN

			local blade = {}
			task.blade = blade

			blade.u1 = u1
			blade.alive = true

			blade.start_center = u1.shape:center()
			blade.shape = circle_mod.by_center_and_radius(
				u1.shape:center(),
				3
			)
			blade.speed = blade.u1:direction() * S1_SPEED * FRAME_DURATION

			function blade:on_enter_collider(e)
				local blade = self

				if e ~= blade.u1 and e.damage then
					e:damage(S1_DAMAGE)
				end
			end

			function blade:tick()
				local blade = self

				blade.shape = blade.shape:move_center(blade.speed)
				if (blade.start_center - blade.shape:center()):length() > S1_RANGE or not blade.shape:wrapper():intersects(frame().map:rect()) then
					frame():remove(blade)
					blade.alive = false
				end
			end

			function blade:draw(viewport)
				local blade = self

				viewport:draw_shape(blade.shape, 0, 0, 255)
			end

			frame():add(blade)
		end

		function task:tick(entity)
			local task = self

			if not task.blade.alive then
				entity:remove_task(task)
			end
		end

		function task:on_cancel(entity)
			local task = self

			frame():remove(task.blade)
		end

		u1:add_task(task)
	end

	function u1:use_s2_skill()
		local u1 = self

		local task = { class = "u1_s2" }

		function task:init(u1)
			local task = self

			u1.s2_cooldown = S2_COOLDOWN

			local dagger = {}

			dagger.start_point = u1.shape:center()
			dagger.landed = false
			dagger.direction = u1:direction()

			if #u1.dagger_list == S2_MAX_DAGGERS then
				frame():remove(u1.dagger_list[1])
				table.remove(u1.dagger_list, 1)
			end
			table.insert(u1.dagger_list, dagger)

			dagger.u1 = u1
			dagger.shape = circle_mod.by_center_and_radius(
				u1.shape:center(),
				3
			)

			function dagger:land()
				local dagger = self

				self.landed = true
			end

			function dagger:on_enter_collider(entity)
				if entity ~= self.u1
					and entity ~= self
					and entity.damage then
						entity:damage(S2_DAMAGE)
				end
			end

			function dagger:tick()
				local dagger = self

				if (dagger.shape:center() - dagger.start_point):length() >= S2_RANGE then
					if not dagger.landed then
						dagger:land()
					end
				else
					dagger.shape = dagger.shape:move_center(dagger.direction * S2_SPEED * FRAME_DURATION)
				end
			end

			function dagger:draw(viewport)
				local dagger = self

				viewport:draw_shape(dagger.shape, 200, 200, 255)
			end

			frame():add(dagger)

			u1:remove_task(task)
		end

		u1:add_task(task)
	end

	function u1:use_s3_skill()
		local u1 = self

		local task = { class = "u1_s3" }
		task.start_point = u1.shape:center()
		task.u1 = u1
		u1.s3_cooldown = S3_COOLDOWN

		task.direction = u1:direction()

		function task:init(u1)
			local task = self

			for _, entity in pairs(u1.colliders) do
				task:damage_entity(entity)
			end
		end

		function task:damage_entity(entity)
			local task = self

			if table.contains(task.u1.dagger_list, entity) then
				task.u1.s3_cooldown = 0
			elseif entity ~= u1 and entity.damage then
				entity:damage(S3_DAMAGE)
			end
		end

		function task:tick(u1)
			local task = self

			if (task.start_point - u1.shape:center()):length() >= S3_RANGE then
				u1:remove_task(task)
			else
				u1.shape = u1.shape:move_center(task.direction:with_length(S3_SPEED * FRAME_DURATION))
			end
		end

		function task:on_enter_collider(u1, entity)
			local task = self

			task:damage_entity(entity)
		end

		u1:add_task(task)
	end

	function u1:mk_s4_aoe()
		local u1 = self

		local aoe = {}

		aoe.u1 = self
		aoe.shape = circle_mod.by_center_and_radius(
			u1.shape:center(),
			S4_RANGE
		)
		aoe.life_counter = S4_DURATION

		function aoe:initial_damage()
			local aoe = self

			local dmg = S4_DAMAGE
			local colliders = frame():find_colliders(aoe.shape)
			local obsolete_daggers = {}
			for _, dagger in pairs(aoe.u1.dagger_list) do
				if dagger.landed and table.contains(colliders, dagger) then
					table.insert(obsolete_daggers, dagger)
					dmg = dmg + S4_DAMAGE_ADD
				end
			end

			for _, dagger in pairs(obsolete_daggers) do
					frame():remove(dagger)
					table.remove_val(aoe.u1.dagger_list, dagger)
					table.remove_val(colliders, dagger)
			end

			for _, entity in pairs(colliders) do
				if entity ~= aoe
					and entity ~= aoe.u1
					and entity.damage then
						entity:damage(dmg)
				end
			end
		end

		function aoe:tick()
			local aoe = self

			aoe.life_counter = aoe.life_counter - FRAME_DURATION
			if aoe.life_counter <= 0 then
				frame():remove(aoe)
			end
		end

		function aoe:draw(viewport)
			local aoe = self

			viewport:draw_shape(self.shape, 100, 100, 100, 100)
		end

		aoe:initial_damage()

		return aoe
	end


	function u1:use_s4_skill()
		local u1 = self

		local task = { class = "u1_s4" }

		function task:init(u1)
			local task = self

			u1.s4_cooldown = S4_COOLDOWN

			local aoe = u1:mk_s4_aoe()
			frame():add(aoe)
		end

		u1:add_task(task)
	end

	function u1:char_tick()
		local u1 = self

		self.s1_cooldown = math.max(0, self.s1_cooldown - FRAME_DURATION)
		self.s2_cooldown = math.max(0, self.s2_cooldown - FRAME_DURATION)
		self.s3_cooldown = math.max(0, self.s3_cooldown - FRAME_DURATION)
		self.s4_cooldown = math.max(0, self.s4_cooldown - FRAME_DURATION)

		if not self.inputs[S1_KEY] then
			self.s1_released = true
		end

		if not self.inputs[S2_KEY] then
			self.s2_released = true
		end

		if not self.inputs[S3_KEY] then
			self.s3_released = true
		end

		if not self.inputs[S4_KEY] then
			self.s4_released = true
		end

		if self.s1_released and self.inputs[S1_KEY] and self.s1_cooldown == 0 then
			self:use_s1_skill()
			self.s1_released = false
		end

		if self.s2_released and self.inputs[S2_KEY] and self.s2_cooldown == 0 then
			self:use_s2_skill()
			self.s2_released = false
		end

		if self.s3_released and self.inputs[S3_KEY] and self.s3_cooldown == 0 then
			self:use_s3_skill()
			self.s3_released = false
		end

		if self.s4_released and self.inputs[S4_KEY] and self.s4_cooldown == 0 then
			self:use_s4_skill()
			self.s4_released = false
		end
	end

	function u1:draw(viewport)
		local u1 = self

		if self:has_tasks_by_class("dead") then
			return
		end

		local alpha = nil
		if u1:has_tasks_by_class("u1_s1") then
			alpha = 100
		else
			alpha = 255
		end

		viewport:draw_shape(self.shape, 100, 100, 100, alpha) -- draw_body
		self:draw_health(viewport)
		self:draw_skills(viewport)
	end

	function u1:damage(dmg)
		local u1 = self

		if not u1:has_tasks_by_class("u1_s1") then
			self.health = math.max(0, self.health - dmg)
			if u1.health == 0 then
				self:die()
			end
		end

	end

	return u1
end
