-- unnamed character 1

local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local circle_mod = require('shape/circle')

local collision_detection_mod = require('collision/detection')

local S1_COOLDOWN = 500
local S1_RANGE = 75
local S1_DAMAGE = 20

local S2_COOLDOWN = 200
local S2_RANGE = 120
local S2_SPEED = 3
local S2_MAX_DAGGERS = 4
local S2_DAMAGE = 5

local S3_COOLDOWN = 300
local S3_RANGE = 100
local S3_SPEED = 2
local S3_DAMAGE = 12

local S4_COOLDOWN = 75
local S4_DAMAGE = 15
local S4_DAMAGE_ADD = 15
local S4_RANGE = 25

return function (u1)

	u1.dagger_list = {}

	u1.s1_cooldown = 0
	u1.s2_cooldown = 0
	u1.s3_cooldown = 0
	u1.s4_cooldown = 0

	u1.s3_released = true

	function u1:use_s1_skill(frame)
		local u1 = self

		local task = { class = "u1_s1" }

		function task:init(u1, frame)
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
			blade.speed = blade.u1:direction()

			function blade:on_enter_collider(frame, e)
				local blade = self

				if e ~= blade.u1 and e.damage then
					e:damage(S1_DAMAGE)
				end
			end

			function blade:tick(frame)
				local blade = self

				blade.shape = blade.shape:move_center(blade.speed)
				if (blade.start_center - blade.shape:center()):length() > S1_RANGE or not blade.shape:wrapper():intersects(frame.map:rect()) then
					frame:remove(blade)
					blade.alive = false
				end
			end

			function blade:draw(viewport)
				local blade = self

				viewport:draw_shape(blade.shape, 0, 0, 255)
			end

			frame:add(blade)
		end

		function task:tick(entity, frame)
			local task = self

			if not task.blade.alive then
				entity:remove_task(task)
			end
		end

		function task:on_cancel(entity, frame)
			local task = self

			frame:remove(task.blade)
		end

		u1:add_task(task)
	end

	function u1:use_s2_skill(frame)
		local u1 = self

		local task = { class = "u1_s2" }

		function task:init(u1, frame)
			local task = self

			u1.s2_cooldown = S2_COOLDOWN

			local dagger = {}

			dagger.start_point = u1.shape:center()
			dagger.landed = false
			dagger.direction = u1:direction()

			if #u1.dagger_list == S2_MAX_DAGGERS then
				frame:remove(u1.dagger_list[1])
				table.remove(u1.dagger_list, 1)
			end
			table.insert(u1.dagger_list, dagger)

			dagger.u1 = u1
			dagger.shape = circle_mod.by_center_and_radius(
				u1.shape:center(),
				3
			)

			function dagger:land(frame)
				local dagger = self

				self.landed = true
			end

			function dagger:on_enter_collision(entity, frame)
				if entity ~= self.u1
					and entity ~= self
					and entity.damage then
						entity:damage(S2_DAMAGE)
				end
			end

			function dagger:tick(frame)
				local dagger = self

				if (dagger.shape:center() - dagger.start_point):length() >= S2_RANGE then
					if not dagger.landed then
						dagger:land(frame)
					end
				else
					dagger.shape = dagger.shape:move_center(dagger.direction * S2_SPEED)
				end
			end

			function dagger:draw(viewport)
				local dagger = self

				viewport:draw_shape(dagger.shape, 200, 200, 255)
			end

			frame:add(dagger)

			u1:remove_task(task)
		end

		u1:add_task(task)
	end

	function u1:use_s3_skill(frame)
		local u1 = self

		local task = { class = "u1_s3" }
		task.start_point = u1.shape:center()
		task.u1 = u1
		u1.s3_cooldown = S3_COOLDOWN
		u1.s3_released = false

		task.direction = u1:direction()

		function task:init(u1, frame)
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

		function task:tick(u1, frame)
			local task = self

			if (task.start_point - u1.shape:center()):length() >= S3_RANGE then
				u1:remove_task(task)
			else
				u1.shape = u1.shape:move_center(task.direction:with_length(S3_SPEED))
			end
		end

		function task:on_enter_collider(u1, frame, entity)
			local task = self

			task:damage_entity(entity)
		end

		u1:add_task(task)
	end

	function u1:mk_s4_aoe(frame)
		local u1 = self

		local aoe = {}

		aoe.u1 = self
		aoe.shape = circle_mod.by_center_and_radius(
			u1.shape:center(),
			S4_RANGE
		)
		aoe.life_counter = 80

		function aoe:initial_damage(frame)
			local aoe = self

			local dmg = S4_DAMAGE
			local colliders = frame:find_colliders(aoe.shape)
			local obsolete_daggers = {}
			for _, dagger in pairs(aoe.u1.dagger_list) do
				if dagger.landed and table.contains(colliders, dagger) then
					table.insert(obsolete_daggers, dagger)
					dmg = dmg + S4_DAMAGE_ADD
				end
			end

			for _, dagger in pairs(obsolete_daggers) do
					frame:remove(dagger)
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

		function aoe:tick(frame)
			local aoe = self

			aoe.life_counter = aoe.life_counter - 1
			if aoe.life_counter <= 0 then
				frame:remove(aoe)
			end
		end

		function aoe:draw(viewport)
			local aoe = self

			viewport:draw_shape(self.shape, 100, 100, 100, 100)
		end

		aoe:initial_damage(frame)

		return aoe
	end


	function u1:use_s4_skill(frame)
		local u1 = self

		local task = { class = "u1_s4" }

		function task:init(u1, frame)
			local task = self

			u1.s4_cooldown = S4_COOLDOWN

			local aoe = u1:mk_s4_aoe(frame)
			frame:add(aoe)
		end

		u1:add_task(task)
	end

	function u1:char_tick(frame)
		local u1 = self

		self.s1_cooldown = math.max(0, self.s1_cooldown - 1)
		self.s2_cooldown = math.max(0, self.s2_cooldown - 1)
		self.s3_cooldown = math.max(0, self.s3_cooldown - 1)
		self.s4_cooldown = math.max(0, self.s4_cooldown - 1)

		if not self.inputs[S3_KEY] then
			self.s3_released = true
		end

		if self.inputs[S1_KEY] and self.s1_cooldown == 0 then
			self:use_s1_skill(frame)
		end

		if self.inputs[S2_KEY] and self.s2_cooldown == 0 then
			self:use_s2_skill(frame)
		end

		if self.s3_released and self.inputs[S3_KEY] and self.s3_cooldown == 0 then
			self:use_s3_skill(frame)
		end

		if self.inputs[S4_KEY] and self.s4_cooldown == 0 then
			self:use_s4_skill(frame)
		end
	end

	function u1:draw(viewport)
		local u1 = self

		local alpha = nil
		if u1:has_tasks_by_class("u1_s1") then
			alpha = 100
		else
			alpha = 255
		end
		viewport:draw_shape(self.shape, 100, 100, 100, alpha)

		local bar_offset = 10
		local bar_height = 3

		local wrapper = self.shape:wrapper()
		viewport:draw_world_rect(rect_mod.by_left_top_and_size(
			wrapper:left_top() - vec_mod(0, bar_offset),
			vec_mod(wrapper:width() * self.health/100, bar_height)
		), 255, 0, 0)
	end

	function u1:damage(dmg)
		local u1 = self

		if not u1:has_tasks_by_class("u1_s1") then
			self.health = math.max(0, self.health - dmg)
		end
	end

	return u1
end
