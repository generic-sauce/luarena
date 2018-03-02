local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local polygon_mod = require('shape/polygon')
local collision_detection_mod = require('collision/detection')

return function (archer)

	archer.s1_cooldown = 0

	function archer:new_arrow(frame)
		local arrow = {}

		arrow.owner = self
		arrow.shape = polygon_mod.by_rect(rect_mod.by_center_and_size(
			self.shape:center(),
			vec_mod(4, 4),
			frame.map
		))
		arrow.speed = self:direction():normalized() * 2

		function arrow:on_enter_collider(frame, e)
			if e.damage and e ~= self.owner then
				e:damage(20)
				frame:remove(self)
			end
		end

		function arrow:tick(frame)
			self.shape = self.shape:move_center(self.speed)
			if not collision_detection_mod(polygon_mod.by_rect(frame.map:rect(), frame), self.shape) then
				frame:remove(self)
			end

		end

		function arrow:draw(viewport)
			viewport:draw_shape(self.shape, 0, 0, 255)
		end

		return arrow
	end

	function archer:char_tick(frame)
		self.s1_cooldown = math.max(0, self.s1_cooldown - 1)
		if self.inputs[S1_KEY] and self.s1_cooldown == 0 then
			self.s1_cooldown = 100
			frame:add(self:new_arrow(frame))
		end
	end

	return archer
end
