-- unnamed character 1

local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local circle_mod = require('shape/circle')

local collision_detection_mod = require('collision/detection')

local H_COOLDOWN = 500
local H_RANGE = 75
local H_DAMAGE = 20

local J_COOLDOWN = 200
local J_RANGE = 120
local J_SPEED = 3
local J_MAX_DAGGERS = 4
local J_DAMAGE = 5

local K_COOLDOWN = 300
local K_RANGE = 100
local K_SPEED = 2
local K_DAMAGE = 12

local L_COOLDOWN = 75
local L_DAMAGE = 15
local L_DAMAGE_ADD = 15
local L_RANGE = 25

return function (u1)

	u1.dagger_list = {}

	u1.h_cooldown = 0
	u1.j_cooldown = 0
	u1.k_cooldown = 0
	u1.l_cooldown = 0

	u1.k_released = true

	function u1:use_h_skill(frame)
		local u1 = self

		local task = { class = "u1_h" }

		function task:init(u1, frame)
			local task = self

			u1.h_cooldown = H_COOLDOWN

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
					e:damage(H_DAMAGE)
				end
			end

			function blade:tick(frame)
				local blade = self

				blade.shape = blade.shape:move_center(blade.speed)
				if (blade.start_center - blade.shape:center()):length() > H_RANGE or not blade.shape:wrapper():intersects(frame.map:rect()) then
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

	function u1:use_j_skill(frame)
		local u1 = self

		local task = { class = "u1_j" }

		function task:init(u1, frame)
			local task = self

			u1.j_cooldown = J_COOLDOWN

			local dagger = {}

			dagger.start_point = u1.shape:center()
			dagger.landed = false
			dagger.direction = u1:direction()

			if #u1.dagger_list == J_MAX_DAGGERS then
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
						entity:damage(J_DAMAGE)
				end
			end

			function dagger:tick(frame)
				local dagger = self

				if (dagger.shape:center() - dagger.start_point):length() >= J_RANGE then
					if not dagger.landed then
						dagger:land(frame)
					end
				else
					dagger.shape = dagger.shape:move_center(dagger.direction * J_SPEED)
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

	function u1:use_k_skill(frame)
		local u1 = self

		local task = { class = "u1_k" }
		task.start_point = u1.shape:center()
		task.u1 = u1
		u1.k_cooldown = K_COOLDOWN
		u1.k_released = false

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
				task.u1.k_cooldown = 0
			elseif entity ~= u1 and entity.damage then
				entity:damage(K_DAMAGE)
			end
		end

		function task:tick(u1, frame)
			local task = self

			if (task.start_point - u1.shape:center()):length() >= K_RANGE then
				u1:remove_task(task)
			else
				u1.shape = u1.shape:move_center(task.direction:with_length(K_SPEED))
			end
		end

		function task:on_enter_collider(u1, frame, entity)
			local task = self

			task:damage_entity(entity)
		end

		u1:add_task(task)
	end

	function u1:mk_l_aoe(frame)
		local u1 = self

		local aoe = {}

		aoe.u1 = self
		aoe.shape = circle_mod.by_center_and_radius(
			u1.shape:center(),
			L_RANGE
		)
		aoe.life_counter = 80

		function aoe:initial_damage(frame)
			local aoe = self

			local dmg = L_DAMAGE
			local colliders = frame:find_colliders(aoe.shape)
			local obsolete_daggers = {}
			for _, dagger in pairs(aoe.u1.dagger_list) do
				if dagger.landed and table.contains(colliders, dagger) then
					table.insert(obsolete_daggers, dagger)
					dmg = dmg + L_DAMAGE_ADD
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


	function u1:use_l_skill(frame)
		local u1 = self

		local task = { class = "u1_l" }

		function task:init(u1, frame)
			local task = self

			u1.l_cooldown = L_COOLDOWN

			local aoe = u1:mk_l_aoe(frame)
			frame:add(aoe)
		end

		u1:add_task(task)
	end

	function u1:char_tick(frame)
		local u1 = self

		self.h_cooldown = math.max(0, self.h_cooldown - 1)
		self.j_cooldown = math.max(0, self.j_cooldown - 1)
		self.k_cooldown = math.max(0, self.k_cooldown - 1)
		self.l_cooldown = math.max(0, self.l_cooldown - 1)

		if not self.inputs.k then
			self.k_released = true
		end

		if self.inputs.h and self.h_cooldown == 0 then
			self:use_h_skill(frame)
		end

		if self.inputs.j and self.j_cooldown == 0 then
			self:use_j_skill(frame)
		end

		if self.k_released and self.inputs.k and self.k_cooldown == 0 then
			self:use_k_skill(frame)
		end

		if self.inputs.l and self.l_cooldown == 0 then
			self:use_l_skill(frame)
		end
	end

	function u1:draw(viewport)
		local u1 = self

		local alpha = nil
		if u1:has_tasks_by_class("u1_h") then
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

		if not u1:has_tasks_by_class("u1_h") then
			self.health = math.max(0, self.health - dmg)
		end
	end

	return u1
end
