local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local collision_detection_mod = require('collision/detection')
local line_mod = require('collision/line')

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

				self.owner.s3_cooldown = 0 -- reset dash!
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

	self.skills = skill_mod.make_skills(
		function (default_skill)

			local task = { class = "archer_s1" }

			function task:init(entity)
				frame():add(entity:new_arrow(1))
				entity:remove_task(self)
			end

			self:add_task(task)
		end,

	function archer:execute_s2()
		local task = { class = "archer_s2" }

		function task:init(entity)
			frame():add(entity:new_arrow(-1))
			entity:remove_task(self)
		end

		self:add_task(task)
	end

	function archer:execute_s3()
		local task = { class = "archer_s3", dash_direction = self:direction(), traveled_distance = 0 }

		function task:tick(entity)
			entity.shape = entity.shape:move_center(self.dash_direction:with_length(S3_SPEED * FRAME_DURATION))
			self.traveled_distance = self.traveled_distance + S3_SPEED * FRAME_DURATION
			if self.traveled_distance >= S3_RANGE then
				entity:remove_task(self)
			end
		end

		self:add_task(task)
	end

	return archer
end
