local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local collision_detection_mod = require('collision/detection')

local S1_COOLDOWN = 1
local S1_ARROW_SPEED = 200 -- units per second

return function (archer)

	archer.s1_cooldown = 0

	function archer:new_arrow()
		local arrow = {}

		arrow.owner = self
		arrow.shape = polygon_mod.by_rect(rect_mod.by_center_and_size(
			self.shape:center(),
			vec_mod(4, 4)
		))
		arrow.speed = self:direction():with_length(S1_ARROW_SPEED * FRAME_DURATION) * 2

		function arrow:on_enter_collider(e)
			if e.damage and e ~= self.owner then
				e:damage(20)
				frame():remove(self)
			end
		end

		function arrow:tick()
			self.shape = self.shape:move_center(self.speed)
			if not collision_detection_mod(polygon_mod.by_rect(frame().map:rect()), self.shape) then
				frame():remove(self)
			end

		end

		function arrow:draw(viewport)
			viewport:draw_shape(self.shape, 0, 0, 255)
		end

		return arrow
	end

	function archer:char_tick()
		self.s1_cooldown = math.max(0, self.s1_cooldown - FRAME_DURATION)
		if self.inputs[S1_KEY] and self.s1_cooldown == 0 then
			self.s1_cooldown = S1_COOLDOWN
			frame():add(self:new_arrow())
		end
	end

	return archer
end
