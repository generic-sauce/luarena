-- unnamed character 1

local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

local Q_COOLDOWN = 500
local Q_RANGE = 75
local Q_DAMAGE = 20

local W_COOLDOWN = 100
local W_RANGE = 120
local W_MAX_DAGGERS = 4
local W_DAMAGE = 5

local E_COOLDOWN = 50
local E_JUMP_RANGE = 100
local E_DASH_SPEED = 2
local E_DAMAGE = 12

local R_COOLDOWN = 75
local R_DAMAGE = 15
local R_DAMAGE_ADD = 15
local R_RANGE = 50

return function (u1)

	u1.dagger_list = {}

	u1.q_cooldown = 0
	u1.w_cooldown = 0
	u1.e_cooldown = 0
	u1.r_cooldown = 0

	function u1:use_q_skill(frame)
		local u1 = self

		local task = { class = "u1_q" }

		function task:init(u1, frame)
			local task = self

			u1.q_cooldown = Q_COOLDOWN

			local blade = {}
			task.blade = blade

			blade.u1 = u1
			blade.alive = true

			blade.start_center = u1.shape:center()
			blade.shape = rect_mod.by_center_and_size(
				u1.shape:center(),
				vec_mod(4, 4)
			)
			blade.speed = (u1.inputs.mouse - u1.shape:center()):normalized()

			function blade:on_enter_collider(frame, e)
				local blade = self

				if e ~= blade.u1 and e.damage then
					e:damage(Q_DAMAGE)
				end
			end

			function blade:tick(frame)
				local blade = self

				blade.shape = blade.shape:with_center_keep_size(blade.shape:center() + blade.speed)
				if (blade.start_center - blade.shape:center()):length() > Q_RANGE or not frame.map:rect():surrounds(blade.shape) then
					frame:remove(blade)
					blade.alive = false
				end
			end

			function blade:draw(viewport)
				local blade = self

				viewport:draw_world_rect(blade.shape, 0, 0, 255)
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

	function u1:use_w_skill(frame)
		local u1 = self

		local task = { class = "u1_w" }

		function task:init(u1, frame)
			local task = self

			u1.w_cooldown = W_COOLDOWN

			local dagger = {}

			dagger.timer = 70
			dagger.landed = false

			dagger.u1 = u1
			dagger.shape = rect_mod.by_center_and_size(
				u1.shape:center() + (u1.inputs.mouse - u1.shape:center()):cropped_to(W_RANGE),
				vec_mod(3, 3)
			)

			frame:add(dagger)

			function dagger:land(frame)
				local dagger = self

				self.landed = true
				if #self.u1.dagger_list == W_MAX_DAGGERS then
					frame:remove(self.u1.dagger_list[1])
					table.remove(self.u1.dagger_list, 1)
				end
				table.insert(self.u1.dagger_list, self)

				for key, entity in pairs(frame:find_colliders(self.shape)) do
					if entity ~= self.u1
						and entity ~= self
						and entity.damage then
							entity:damage(W_DAMAGE)
					end
				end
			end

			function dagger:tick(frame)
				local dagger = self

				dagger.timer = math.max(0, dagger.timer - 1)
				if dagger.timer == 0 and not dagger.landed then
					dagger:land(frame)
				end
			end

			function dagger:draw(viewport)
				local dagger = self

				if dagger.landed then
					-- render dagger
					viewport:draw_world_rect(dagger.shape, 200, 200, 255)
				else
					-- render shadow
					viewport:draw_world_rect(rect_mod.by_center_and_size(
						dagger.shape:center(),
						dagger.shape:size() * 3
					), 40, 40, 40, 80)
				end
			end
		end

		u1:add_task(task)
	end

	function u1:use_e_skill(frame)
		local u1 = self

		local task = { class = "u1_e_walk" }

		function task:init(u1, frame)
			local task = self

			local closest = nil
			for _, dagger in pairs(u1.dagger_list) do
				if closest == nil or (dagger.shape:center() - u1.inputs.mouse):length() < (closest.shape:center() - u1.inputs.mouse):length() then
					closest = dagger
				end
			end

			if closest == nil then
				u1:remove_task(task)
			else
				task.walk_target = closest.shape:center()
				u1.e_cooldown = E_COOLDOWN
			end
		end

		function task:tick(u1, frame)
			local task = self

			local move_vec = task.walk_target - u1.shape:center()
			if move_vec:length() < E_JUMP_RANGE then
				local dash_task = { class = "u1_e_dash" }

				dash_task.dash_target = task.walk_target

				function dash_task:tick(u1, frame)
					local dash_task = self

					local move_vec = (dash_task.dash_target - u1.shape:center())
					if move_vec:length() < E_DASH_SPEED then
						u1.shape = u1.shape:with_center_keep_size(dash_task.dash_target)
						u1:remove_task(dash_task)
					else
						u1.shape = u1.shape:with_center_keep_size(u1.shape:center() + move_vec:cropped_to(E_DASH_SPEED))
					end
				end

				function dash_task:on_enter_collider(u1, frame, entity)
					local dash_task = self

					if entity ~= u1 and entity.damage then
						entity:damage(E_DAMAGE)
					end
				end

				u1:add_task(dash_task)
				u1:remove_task(task)
			else
				u1.shape = u1.shape:with_center_keep_size(u1.shape:center() + move_vec:cropped_to(WALKSPEED))
			end
		end

		u1:add_task(task)
	end

	function u1:mk_r_aoe(frame)
		local u1 = self

		local aoe = {}

		aoe.u1 = self
		aoe.shape = rect_mod.by_center_and_size(
			u1.shape:center(),
			vec_mod(1, 1) * R_RANGE
		)
		aoe.life_counter = 80

		function aoe:initial_damage(frame)
			local aoe = self

			local dmg = R_DAMAGE
			local colliders = frame:find_colliders(aoe.shape)
			local obsolete_daggers = {}
			for _, dagger in pairs(aoe.u1.dagger_list) do
				if dagger.landed and table.contains(colliders, dagger) then
					table.insert(obsolete_daggers, dagger)
					dmg = dmg + R_DAMAGE_ADD
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

			viewport:draw_world_rect(self.shape, 100, 100, 100, 100)
		end

		aoe:initial_damage(frame)

		return aoe
	end


	function u1:use_r_skill(frame)
		local u1 = self

		local task = { class = "u1_r" }

		function task:init(u1, frame)
			local task = self

			u1.r_cooldown = R_COOLDOWN

			local aoe = u1:mk_r_aoe(frame)
			frame:add(aoe)
		end

		u1:add_task(task)
	end

	function u1:char_tick(frame)
		local u1 = self

		self.q_cooldown = math.max(0, self.q_cooldown - 1)
		self.w_cooldown = math.max(0, self.w_cooldown - 1)
		self.e_cooldown = math.max(0, self.e_cooldown - 1)
		self.r_cooldown = math.max(0, self.r_cooldown - 1)

		if self.inputs.q and self.q_cooldown == 0 then
			self:use_q_skill(frame)
		end

		if self.inputs.w and self.w_cooldown == 0 then
			self:use_w_skill(frame)
		end

		if self.inputs.e and self.e_cooldown == 0 then
			self:use_e_skill(frame)
		end

		if self.inputs.r and self.r_cooldown == 0 then
			self:use_r_skill(frame)
		end
	end

	function u1:draw(viewport)
		local u1 = self

		local alpha = nil
		if u1:has_tasks_by_class("u1_q") then
			alpha = 100
		else
			alpha = 255
		end
		viewport:draw_world_rect(self.shape, 100, 100, 100, alpha)

		local bar_offset = 10
		local bar_height = 3
		viewport:draw_world_rect(rect_mod.by_left_top_and_size(
			self.shape:left_top() - vec_mod(0, bar_offset),
			vec_mod(self.shape:size().x * self.health/100, bar_height)
		), 255, 0, 0)
	end

	function u1:damage(dmg)
		local u1 = self

		if not u1:has_tasks_by_class("u1_q") then
			self.health = math.max(0, self.health - dmg)
		end
	end

	return u1
end
