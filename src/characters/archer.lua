local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local collision_detection_mod = require('collision/detection')
local line_mod = require('collision/line')
local skill_mod = require('frame/skill')

local S1_2_COOLDOWN = 0.5
local S1_2_RANGE = 100
local S1_2_ARROW_SPEED = 600 -- units per second
local S1_2_DAMAGE = 10

local S3_SPEED = 600
local S3_RANGE = 50

return function (archer)

	function archer:color()
		return 30, 50, 20
	end

	function archer:new_arrow(dir) -- dir=1 => forward, dir=-1 => backward
		assert(dir == 1 or dir == -1)
		assert(self)

		local arrow = {}

		arrow.owner = self
		arrow.traveled_distance = 0
		arrow.speed = self:direction():with_length(S1_2_ARROW_SPEED * FRAME_DURATION) * dir

		local center = self.shape:center()
		local front = arrow.speed:with_length(5)
		local right = line_mod(center, center + arrow.speed):right():with_length(1)

		arrow.shape = polygon_mod.by_center_and_points(
			center,
			{
				vec_mod(0, 0) + front + right,
				vec_mod(0, 0) + front - right,
				vec_mod(0, 0) - front - right,
				vec_mod(0, 0) - front + right
			}
		)

		function arrow:on_enter_collider(e)
			if e.damage and e ~= self.owner then
				e:damage(S1_2_DAMAGE)
				frame():remove(self)

				self.owner.skills[3].ready = true -- reset dash!
			end
		end

		function arrow:tick()
			self.shape = self.shape:move_center(self.speed)
			self.traveled_distance = self.traveled_distance + S1_2_ARROW_SPEED * FRAME_DURATION
			if self.traveled_distance >= S1_2_RANGE or
					not collision_detection_mod(polygon_mod.by_rect(frame().map:rect()), self.shape) then
				frame():remove(self)
			end

		end

		function arrow:draw(viewport)
			viewport:draw_shape(self.shape, 150, 90, 0)
		end

		return arrow
	end

	function archer:shoot_arrow(dir)
		frame():add(self:new_arrow(dir))
	end

	archer.skills = {
		(function()
			local skill = skill_mod.make_blank_skill(archer, 1)
			skill_mod.with_cooldown(skill, S1_2_COOLDOWN)
			skill_mod.with_fresh_key(skill)
			skill_mod.with_instant(skill, function(self) self.owner:shoot_arrow(1) end)
			return skill
		end)(),

		(function()
			local skill = skill_mod.make_blank_skill(archer, 2)
			skill_mod.with_cooldown(skill, S1_2_COOLDOWN)
			skill_mod.with_fresh_key(skill)
			skill_mod.with_instant(skill, function(self) self.owner:shoot_arrow(-1) end)
			return skill
		end)(),

		(function ()
			local skill = skill_mod.make_blank_skill(archer, 3)
			skill.ready = false

			skill_mod.append_function(skill.task, "init", function(self)
				self.traveled_distance = 0
				self.dash_direction = self.owner:direction()
			end)

			skill_mod.append_function(skill, "go_condition", function(self)
				return self.ready
			end)

			skill_mod.append_function(skill, "go", function(self)
				self.ready = false
			end)

			skill_mod.append_function(skill.task, "tick", function(self)
				self.owner.shape = self.owner.shape:move_center(self.dash_direction:with_length(S3_SPEED * FRAME_DURATION))
				self.traveled_distance = self.traveled_distance + S3_SPEED * FRAME_DURATION
				if self.traveled_distance >= S3_RANGE then
					self.owner:remove_task(self)
				end
			end)

			function skill:draw(viewport)
				local r, g, b = 255, 0, 0
				if self.ready then
					r, g, b = 0, 255, 0
				end

				local rect = skill_mod.icon_rect_border(self:icon_rect(), viewport)
				viewport:draw_world_rect(rect, r, g, b)
			end

			return skill
		end)()
	}

	return archer
end
