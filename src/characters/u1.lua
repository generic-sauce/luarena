-- unnamed character 1

local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local circle_mod = require('shape/circle')

local collision_detection_mod = require('collision/detection')
local skill_mod = require('frame/skill')

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

	function u1:mk_s4_aoe()
		local aoe = {}

		aoe.owner = self
		aoe.shape = circle_mod.by_center_and_radius(
			aoe.owner.shape:center(),
			S4_RANGE
		)
		aoe.life_counter = S4_DURATION

		function aoe:initial_damage()
			local aoe = self

			local dmg = S4_DAMAGE
			local colliders = frame():find_colliders(aoe.shape)
			local obsolete_daggers = {}
			for _, dagger in pairs(aoe.owner.dagger_list) do
				if dagger.landed and table.contains(colliders, dagger) then
					table.insert(obsolete_daggers, dagger)
					dmg = S4_DAMAGE + S4_DAMAGE_ADD -- dagger damage does not stack
				end
			end

			for _, dagger in pairs(obsolete_daggers) do
					frame():remove(dagger)
					table.remove_val(aoe.owner.dagger_list, dagger)
					table.remove_val(colliders, dagger)
			end

			for _, entity in pairs(colliders) do
				if entity ~= aoe
					and entity ~= aoe.owner
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

	function u1:color()
		if self:has_tasks_by_class("u1_s1") then
			return 160, 160, 200
		else
			return 100, 100, 150
		end
	end

	u1.skills = {
		(function()
			local skill = skill_mod.make_blank_skill(u1, 1)
			skill_mod.with_cooldown(skill, S1_COOLDOWN)
			skill_mod.with_fresh_key(skill)

			skill_mod.append_function(skill.task, "init", function (self)
				local task = self

				local blade = {}
				task.blade = blade

				blade.owner = self.owner
				blade.alive = true

				blade.start_center = self.owner.shape:center()
				blade.shape = circle_mod.by_center_and_radius(
					self.owner.shape:center(),
					3
				)
				blade.speed = self.owner:direction() * S1_SPEED * FRAME_DURATION

				function blade:on_enter_collider(e)
					local blade = self

					if e ~= blade.owner and e.damage then
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
			end)

			skill_mod.append_function(skill.task, "tick", function (self)
				local task = self

				if not task.blade.alive then
					self.owner:remove_task(task)
				end
			end)

			skill_mod.append_function(skill.task, "on_cancel", function (self)
				local task = self

				frame():remove(task.blade)
			end)

			return skill
		end)(),

		(function()
			local skill = skill_mod.make_blank_skill(u1, 2)
			skill_mod.with_cooldown(skill, S2_COOLDOWN)
			skill_mod.with_fresh_key(skill)
			skill_mod.with_instant(skill, function(self)
				local task = self

				self.owner.s2_cooldown = S2_COOLDOWN

				local dagger = {}

				dagger.owner = self.owner
				dagger.start_point = self.owner.shape:center()
				dagger.landed = false
				dagger.direction = self.owner:direction()

				if #self.owner.dagger_list == S2_MAX_DAGGERS then
					frame():remove(self.owner.dagger_list[1])
					table.remove(self.owner.dagger_list, 1)
				end
				table.insert(self.owner.dagger_list, dagger)

				dagger.shape = circle_mod.by_center_and_radius(
					self.owner.shape:center(),
					3
				)

				function dagger:land()
					local dagger = self

					self.landed = true
				end

				function dagger:on_enter_collider(entity)
					if entity ~= self.owner
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
			end)

			return skill
		end)(),

		(function()
			local skill = skill_mod.make_blank_skill(u1, 3)
			skill_mod.with_cooldown(skill, S3_COOLDOWN)
			skill_mod.with_fresh_key(skill)

			skill_mod.append_function(skill.task, "init", function(self)
				local task = self

				task.direction = self.owner:direction()
				task.traveled_distance = 0

				for _, entity in pairs(self.owner.colliders) do
					task:damage_entity(entity)
				end
			end)

			function skill.task:damage_entity(entity)
				local task = self

				if table.contains(self.owner.dagger_list, entity) then
					self.skill.cooldown = 0
				elseif entity ~= self.owner and entity.damage then
					entity:damage(S3_DAMAGE)
				end
			end

			skill_mod.append_function(skill.task, "tick", function(self)
				local task = self

				if task.traveled_distance >= S3_RANGE then
					self.owner:remove_task(task)
				else
					self.owner.shape = self.owner.shape:move_center(task.direction:with_length(S3_SPEED * FRAME_DURATION))
					task.traveled_distance = task.traveled_distance + S3_SPEED * FRAME_DURATION
				end
			end)


			function skill.task:on_enter_collider(owner, entity)
				local task = self

				task:damage_entity(entity)
			end

			return skill
		end)(),

		(function()
			local skill = skill_mod.make_blank_skill(u1, 4)
			skill_mod.with_cooldown(skill, S4_COOLDOWN)
			skill_mod.with_fresh_key(skill)
			skill_mod.with_instant(skill, function(self)
				local aoe = self.owner:mk_s4_aoe()
				frame():add(aoe)
			end)

			return skill
		end)()
	}

	return u1
end
